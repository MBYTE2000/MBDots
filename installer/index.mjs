#!/usr/bin/env node
// MBDots Installer — интерактивный TUI-установщик NixOS.
// Запускать через ../install.sh (тот подготавливает node+deps).

import { existsSync, rmSync } from 'fs';
import { execa } from 'execa';
import chalk from 'chalk';
import ora from 'ora';
import {
  banner,
  stepHeader,
  summaryBox,
  warningBox,
  successBox,
  c,
} from './lib/branding.mjs';
import { preflight, renderChecks, requireRepo } from './lib/util.mjs';
import {
  askDisk,
  askHostname,
  askUsername,
  askGpu,
  askTimezone,
  askLuksPassword,
  confirmWipe,
  confirmReboot,
} from './lib/prompts.mjs';
import {
  prepareWorkdir,
  applyProfile,
  applyGpuProfile,
  stageLuksPassword,
  clearLuksPassword,
  runDisko,
  copyConfigToTarget,
  copyToRepoHome,
  generateHardwareConfig,
  runNixosInstall,
  installUserDotfiles,
  chownUserHome,
  setUserPassword,
} from './lib/steps.mjs';

// --- Аргументы -------------------------------------------------------------
const repoPath = process.argv[2];
if (!repoPath) {
  console.error(c.err('Использование: node index.mjs <путь к репозиторию MBDots>'));
  process.exit(2);
}

// --- Главный поток ---------------------------------------------------------
async function main() {
  process.stdout.write('\x1Bc'); // clear screen
  console.log(banner());

  // 1. Проверки окружения
  console.log(stepHeader(1, 8, 'Предполётные проверки'));
  const checks = await preflight();
  console.log(renderChecks(checks));
  if (checks.some((r) => !r.ok)) {
    console.log(c.err('Часть проверок не прошла. Устрани и запусти снова.'));
    process.exit(1);
  }

  requireRepo(repoPath);
  console.log(c.ok('  ✓  Репозиторий MBDots корректный') + '\n');

  // 2. Параметры
  console.log(stepHeader(2, 8, 'Параметры установки'));
  const disk = await askDisk();
  const hostname = await askHostname('nixos');
  const username = await askUsername('mbyte');
  const gpu = await askGpu();
  const timezone = await askTimezone();
  const luksPassword = await askLuksPassword();

  const cfg = { disk, hostname, username, gpu, timezone };

  // 3. Подтверждение
  console.log(stepHeader(3, 8, 'Подтверждение'));
  console.log(summaryBox(cfg));
  console.log(
    warningBox(
      `Диск ${cfg.disk} будет ПОЛНОСТЬЮ ОЧИЩЕН,\n` +
        'разбит по схеме disko.nix (ESP + LUKS → btrfs subvolumes),\n' +
        'и на него будет установлен NixOS c этим репозиторием.',
    ),
  );
  const ok = await confirmWipe(cfg);
  if (!ok) {
    console.log(c.err('Отменено.'));
    process.exit(1);
  }

  // 4-8. Установка
  const spin = ora({ text: 'Готовлю рабочую копию конфига…', color: 'cyan' });
  spin.start();
  const work = await prepareWorkdir(repoPath);
  applyProfile(work, cfg);
  applyGpuProfile(work, cfg.gpu);
  stageLuksPassword(work, luksPassword);
  spin.succeed('Рабочая копия готова: ' + c.dim(work));

  // Убираем LUKS-пароль из RAM ноды (best-effort; JS GC).
  const luksOverwrite = 'x'.repeat(luksPassword.length);
  void luksOverwrite;

  let workCleaned = false;
  const cleanup = () => {
    if (workCleaned) return;
    workCleaned = true;
    try {
      clearLuksPassword(work);
    } catch {}
    try {
      rmSync(work, { recursive: true, force: true });
    } catch {}
  };
  process.on('exit', cleanup);
  process.on('SIGINT', () => {
    cleanup();
    process.exit(130);
  });

  try {
    await runDisko(work, cfg.disk);
    // Стираем pwfile сразу после disko — до копирования в /mnt.
    clearLuksPassword(work);

    console.log(stepHeader(5, 8, 'Копирование конфига в /mnt/etc/nixos'));
    const cpSpin = ora('Копирую…').start();
    copyConfigToTarget(work);
    cpSpin.succeed('Конфиг скопирован в /mnt/etc/nixos');

    await generateHardwareConfig();

    await runNixosInstall(cfg);

    // Пользовательские dot-файлы + repo в $HOME + symlink /etc/nixos.
    const dotSpin = ora('Пользовательские конфиги и repo в $HOME…').start();
    installUserDotfiles(work, cfg.username);
    await copyToRepoHome(work, cfg.username);
    await chownUserHome(cfg.username);
    dotSpin.succeed('Готово: ~/.config + ~/nixos-config (→ /etc/nixos)');

    await setUserPassword(cfg.username);
  } catch (err) {
    console.log(
      '\n' +
        c.err('Установка упала на одном из шагов:') +
        '\n' +
        c.dim(err.message || err),
    );
    console.log(c.warn('  Рабочая копия сохранена: ' + work));
    console.log(c.warn('  Разбор — журналы disko / nixos-install выше.'));
    workCleaned = true; // не удаляем work, пусть остаётся для дебага
    process.exit(1);
  }

  console.log(
    successBox(
      `Система установлена.\n\n` +
        `  hostname   ${chalk.bold(cfg.hostname)}\n` +
        `  user       ${chalk.bold(cfg.username)}\n` +
        `  gpu        ${chalk.bold(cfg.gpu)}\n` +
        `  timezone   ${chalk.bold(cfg.timezone)}\n\n` +
        `На новой системе:\n` +
        `  • /etc/nixos → /home/${cfg.username}/nixos-config (git-репо)\n` +
        `  • alias ${chalk.bold('update')} → nixos-rebuild switch --flake /etc/nixos#${cfg.hostname}`,
    ),
  );

  if (await confirmReboot()) {
    console.log(c.step('Отмонтирую и перезагружаю…'));
    await execa('sh', ['-c', 'umount -R /mnt || true; reboot'], {
      stdio: 'inherit',
    });
  } else {
    console.log(
      c.dim('  umount -R /mnt && reboot когда будешь готов.') + '\n',
    );
  }
}

main().catch((err) => {
  console.error(c.err('Критическая ошибка: ') + (err.stack || err.message || err));
  process.exit(1);
});
