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
import { STRINGS } from './lib/i18n.mjs';
import {
  askLang, askDisk, askHostnameAndAliases, askUsername, askGpu, askTimezone,
  askNetwork, askDataDisk, askCategories, askLuksPassword,
  confirmWipe, confirmReboot,
} from './lib/prompts.mjs';
import {
  prepareWorkdir, applyProfile, applyGpuProfile, stageLuksPassword,
  clearLuksPassword, runDisko, copyConfigToTarget, copyToRepoHome,
  generateHardwareConfig, runNixosInstall, installUserDotfiles,
  chownUserHome, setUserPassword,
} from './lib/steps.mjs';

const repoPath = process.argv[2];
if (!repoPath) {
  console.error(c.err('Usage: node index.mjs <path to repo>'));
  process.exit(2);
}

async function main() {
  process.stdout.write('\x1Bc');

  // 0. Language (ASCII prompt — before anything else, so font issues don't break it)
  const lang = await askLang();
  const t = STRINGS[lang];

  console.log(banner());

  // 1. Preflight
  console.log(stepHeader(1, 10, t.stepPreflight));
  const checks = await preflight();
  console.log(renderChecks(checks));
  if (checks.some(r => !r.ok)) {
    console.log(c.err(t.checksFailed));
    process.exit(1);
  }
  requireRepo(repoPath);
  console.log(c.ok(t.checksOk) + '\n');

  // 2. Main parameters
  console.log(stepHeader(2, 10, t.stepMain));
  const disk     = await askDisk(t);
  const { hostname, aliases } = await askHostnameAndAliases(t, 'nixos');
  const username = await askUsername(t, 'mbyte');
  const gpu      = await askGpu(t);
  const timezone = await askTimezone(t);

  // 3. Network
  console.log(stepHeader(3, 10, t.stepNetwork));
  const network = await askNetwork(t);
  const dataDisk = await askDataDisk(t);

  // 4. Categories
  console.log(stepHeader(4, 10, t.stepCategories));
  const categories = await askCategories(t);

  // 5. LUKS
  const luksPassword = await askLuksPassword(t);

  const cfg = { disk, hostname, aliases, username, gpu, timezone, network, dataDisk, categories };

  // 6. Confirm
  console.log(summaryBox({
    ...cfg,
    network: network.mode === 'static'
      ? `static ${network.address} via ${network.gateway} on ${network.interface}`
      : 'dhcp',
    aliases: aliases.length ? aliases.join(', ') : '(none)',
    categories: Object.entries(categories).filter(([, v]) => v).map(([k]) => k).join(', ') || '(minimal)',
    dataDisk: dataDisk ? t.yes : t.no,
  }, t.summaryTitle));
  console.log(warningBox(t.warnBody(cfg.disk), t.warnTitle));
  if (!await confirmWipe(t, cfg)) {
    console.log(c.err(t.cancelled));
    process.exit(1);
  }

  // 7-10. Install
  const spin = ora({ text: 'Working copy...', color: 'cyan' }).start();
  const work = await prepareWorkdir(repoPath);
  applyProfile(work, cfg);
  applyGpuProfile(work, cfg.gpu);
  stageLuksPassword(work, luksPassword);
  spin.succeed(t.workdirReady(work));

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

    console.log(stepHeader(6, 10, t.stepCopy));
    const cp = ora(t.copying).start();
    try {
      await copyConfigToTarget(work);
      cp.succeed(t.copyDone);
    } catch (e) {
      cp.fail(t.copying + ' — ' + (e.message || e));
      throw e;
    }

    await generateHardwareConfig();
    await runNixosInstall(cfg);

    const dot = ora('Dotfiles...').start();
    installUserDotfiles(work, cfg.username);
    await copyToRepoHome(work, cfg.username);
    await chownUserHome(cfg.username);
    dot.succeed(t.dotfilesDone);

    await setUserPassword(cfg.username);
  } catch (err) {
    console.log('\n' + c.err('Error:') + ' ' + c.dim(err.message || err));
    console.log(c.warn('  Work dir kept for debug: ' + work));
    cleanedUp = true;
    process.exit(1);
  }

  console.log(successBox(
    `${t.installedOk}\n\n` +
    `  hostname    ${chalk.bold(cfg.hostname)}` +
    (cfg.aliases.length ? ` (aliases: ${cfg.aliases.join(', ')})` : '') + `\n` +
    `  user        ${chalk.bold(cfg.username)}\n` +
    `  gpu         ${chalk.bold(cfg.gpu)}\n` +
    `  network     ${chalk.bold(cfg.network.mode)}` +
      (cfg.network.mode === 'static' ? ` (${cfg.network.address})` : '') + `\n` +
    `  dataDisk    ${cfg.dataDisk ? t.yes : t.no}\n` +
    `  categories  ${chalk.bold(Object.entries(cfg.categories).filter(([,v])=>v).map(([k])=>k).join(', ') || 'minimal')}\n\n` +
    `/etc/nixos -> /home/${cfg.username}/nixos-config (git repo)\n` +
    `alias ${chalk.bold('update')} -> nixos-rebuild switch --flake /etc/nixos#${cfg.hostname}`,
    t.successTitle,
  ));

  cleanup();
  console.log(c.ok(t.tempCleaned));

  if (await confirmReboot(t)) {
    console.log(c.step(t.unmounting));
    await execa('sh', ['-c', 'umount -R /mnt || true; reboot'], { stdio: 'inherit' });
  } else {
    console.log(c.dim(t.nothingNow) + '\n');
  }
}

main().catch(err => {
  console.error(c.err('Fatal: ') + (err.stack || err.message || err));
  process.exit(1);
});
