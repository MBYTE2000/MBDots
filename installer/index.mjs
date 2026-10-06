#!/usr/bin/env node
// MBDots Installer — интерактивный TUI-установщик NixOS.
// Запускать через ../install.sh.

import { rmSync } from 'fs';
import { execa } from 'execa';
import chalk from 'chalk';
import ora from 'ora';
import {
  banner, stepHeader, summaryBox, warningBox, successBox, c,
} from './lib/branding.mjs';
import { preflight, renderChecks, requireRepo } from './lib/util.mjs';
import {
  askDisk, askHostnameAndAliases, askUsername, askGpu, askTimezone,
  askNetwork, askDataDisk, askCategories, askLuksPassword, confirmWipe, confirmReboot,
} from './lib/prompts.mjs';
import {
  prepareWorkdir, applyProfile, applyGpuProfile, stageLuksPassword,
  clearLuksPassword, runDisko, copyConfigToTarget, copyToRepoHome,
  generateHardwareConfig, runNixosInstall, installUserDotfiles,
  chownUserHome, setUserPassword,
} from './lib/steps.mjs';

const repoPath = process.argv[2];
if (!repoPath) {
  console.error(c.err('Использование: node index.mjs <путь к репо>'));
  process.exit(2);
}

async function main() {
  process.stdout.write('\x1Bc');
  console.log(banner());

  // 1. Preflight
  console.log(stepHeader(1, 10, 'Предполётные проверки'));
  const checks = await preflight();
  console.log(renderChecks(checks));
  if (checks.some(r => !r.ok)) {
    console.log(c.err('Часть проверок провалилась.'));
    process.exit(1);
  }
  requireRepo(repoPath);
  console.log(c.ok('  ✓  Репозиторий MBDots корректный') + '\n');

  // 2. Диск + hostname + user + GPU + timezone
  console.log(stepHeader(2, 10, 'Основные параметры'));
  const disk     = await askDisk();
  const { hostname, aliases } = await askHostnameAndAliases('nixos');
  const username = await askUsername('mbyte');
  const gpu      = await askGpu();
  const timezone = await askTimezone();

  // 3. Сеть (static — default)
  console.log(stepHeader(3, 10, 'Сеть'));
  const network = await askNetwork();

  // 3b. Второй NVMe под /mnt/data
  const dataDisk = await askDataDisk();

  // 4. Категории
  console.log(stepHeader(4, 10, 'Категории ПО'));
  const categories = await askCategories();

  // 5. LUKS
  const luksPassword = await askLuksPassword();

  const cfg = { disk, hostname, aliases, username, gpu, timezone, network, dataDisk, categories };

  // 6. Подтверждение
  console.log(summaryBox({
    ...cfg,
    network: network.mode === 'static'
      ? `static ${network.address} via ${network.gateway} on ${network.interface}`
      : 'dhcp',
    aliases: aliases.length ? aliases.join(', ') : '(нет)',
    categories: Object.entries(categories).filter(([, v]) => v).map(([k]) => k).join(', ') || '(минимум)',
  }));
  console.log(warningBox(
    `Диск ${cfg.disk} будет ПОЛНОСТЬЮ ОЧИЩЕН,\n` +
    'разбит по disko.nix (ESP + LUKS → btrfs subvolumes),\n' +
    'и на него будет установлен NixOS с этим репо.',
  ));
  if (!await confirmWipe(cfg)) { console.log(c.err('Отменено.')); process.exit(1); }

  // 7-10. Установка
  const spin = ora({ text: 'Рабочая копия конфига…', color: 'cyan' }).start();
  const work = await prepareWorkdir(repoPath);
  applyProfile(work, cfg);
  applyGpuProfile(work, cfg.gpu);
  stageLuksPassword(work, luksPassword);
  spin.succeed('Рабочая копия готова: ' + c.dim(work));

  let cleanedUp = false;
  const cleanup = () => {
    if (cleanedUp) return;
    cleanedUp = true;
    try { clearLuksPassword(work); } catch {}
    try { rmSync(work, { recursive: true, force: true }); } catch {}
    try { rmSync('/tmp/mbdots-luks-password', { force: true }); } catch {}
  };
  process.on('exit', cleanup);
  process.on('SIGINT', () => { cleanup(); process.exit(130); });

  try {
    await runDisko(work, cfg.disk);
    clearLuksPassword(work);

    console.log(stepHeader(6, 10, 'Копирование конфига в /mnt/etc/nixos'));
    const cp = ora('Копирую…').start();
    copyConfigToTarget(work);
    cp.succeed('Готово');

    await generateHardwareConfig();
    await runNixosInstall(cfg);

    const dot = ora('Dot-файлы + repo в $HOME…').start();
    installUserDotfiles(work, cfg.username);
    await copyToRepoHome(work, cfg.username);
    await chownUserHome(cfg.username);
    dot.succeed('Готово: ~/.config + ~/nixos-config (→ /etc/nixos)');

    await setUserPassword(cfg.username);
  } catch (err) {
    console.log('\n' + c.err('Ошибка:') + ' ' + c.dim(err.message || err));
    console.log(c.warn('  Рабочая копия сохранена для разбора: ' + work));
    cleanedUp = true;
    process.exit(1);
  }

  console.log(successBox(
    `Система установлена.\n\n` +
    `  hostname    ${chalk.bold(cfg.hostname)}` +
    (cfg.aliases.length ? ` (aliases: ${cfg.aliases.join(', ')})` : '') + `\n` +
    `  user        ${chalk.bold(cfg.username)}\n` +
    `  gpu         ${chalk.bold(cfg.gpu)}\n` +
    `  network     ${chalk.bold(cfg.network.mode)}` +
      (cfg.network.mode === 'static' ? ` (${cfg.network.address})` : '') + `\n` +
    `  categories  ${chalk.bold(Object.entries(cfg.categories).filter(([,v])=>v).map(([k])=>k).join(', ') || 'минимум')}\n\n` +
    `На новой системе:\n` +
    `  • /etc/nixos → /home/${cfg.username}/nixos-config (git-репо)\n` +
    `  • alias ${chalk.bold('update')} → nixos-rebuild switch --flake /etc/nixos#${cfg.hostname}`,
  ));

  // Явный cleanup перед exit — чтобы не остались /tmp/mbdots-XXX и pwfile.
  cleanup();
  console.log(c.ok('Временные файлы установщика удалены.'));

  if (await confirmReboot()) {
    console.log(c.step('Отмонтирую /mnt и перезагружаю…'));
    await execa('sh', ['-c', 'umount -R /mnt || true; reboot'], { stdio: 'inherit' });
  } else {
    console.log(c.dim('  umount -R /mnt && reboot когда будешь готов.') + '\n');
  }
}

main().catch(err => {
  console.error(c.err('Критическая ошибка: ') + (err.stack || err.message || err));
  process.exit(1);
});
