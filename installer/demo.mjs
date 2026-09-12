#!/usr/bin/env node
// Демонстрация визуалки MBDots installer — без реальной установки, без
// интерактивных промптов. Просто прогоняет все экраны последовательно.

import chalk from 'chalk';
import {
  banner,
  stepHeader,
  summaryBox,
  warningBox,
  successBox,
  c,
} from './lib/branding.mjs';
import { renderChecks } from './lib/util.mjs';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// --- 1. Баннер ------------------------------------------------------------
process.stdout.write('\x1Bc');
console.log(banner());
await sleep(700);

// --- 2. Preflight (симуляция — все ✓) ------------------------------------
console.log(stepHeader(1, 8, 'Предполётные проверки'));
const fakeChecks = [
  { label: 'запуск от root', ok: true },
  { label: 'nix в PATH', ok: true },
  { label: 'nixos-install в PATH', ok: true },
  { label: 'lsblk доступен', ok: true },
  { label: 'интернет (cache.nixos.org)', ok: true },
];
console.log(renderChecks(fakeChecks));
console.log(c.ok('  ✓  Репозиторий MBDots корректный') + '\n');
await sleep(700);

// --- 3. Параметры (симуляция prompts как «скриншот») ---------------------
console.log(stepHeader(2, 8, 'Параметры установки'));

const promptLine = (label, hint, value) =>
  chalk.magenta('? ') +
  chalk.bold(label) + ' ' +
  chalk.gray('(' + hint + ')') + ' ' +
  chalk.cyan('› ') +
  chalk.bold(value);

console.log('');
console.log(promptLine('Выбери целевой диск:', 'стрелки ↑↓, Enter', '/dev/nvme0n1  1.9T  Samsung SSD 990 PRO 2TB'));
console.log('  ' + chalk.gray('NVME'));
console.log('  ' + chalk.gray('  /dev/nvme1n1     916G  Samsung SSD 970 EVO Plus 1TB'));
console.log('  ' + chalk.gray('  /dev/sda         500G  WDC WD5000AAKX-001CA0'));
console.log('');
console.log(promptLine('Hostname:', 'буквы/цифры/дефис', 'workstation'));
console.log(promptLine('Имя основного пользователя:', 'unix-username', 'alice'));
console.log('');
console.log(promptLine('GPU-профиль:', '', 'NVIDIA'));
console.log('  ' + chalk.gray('  NVIDIA  — проприетарный драйвер (nvidiaPackages.beta)'));
console.log('  ' + chalk.gray('  AMD     — amdgpu / mesa'));
console.log('  ' + chalk.gray('  Intel   — i965/iHD, VAAPI'));
console.log('  ' + chalk.gray('  None    — без отдельного GPU (VM/сервер)'));
console.log('');
console.log(promptLine('Timezone:', 'набирай для фильтра', 'Europe/Minsk'));
console.log('');
console.log(promptLine('LUKS-пароль:', 'мин. 6 символов', '••••••••••'));
console.log(promptLine('Повтори пароль:', '', '••••••••••'));
await sleep(700);

// --- 4. Confirmation -----------------------------------------------------
console.log(stepHeader(3, 8, 'Подтверждение'));
const cfg = {
  disk: '/dev/nvme0n1',
  hostname: 'workstation',
  username: 'alice',
  gpu: 'nvidia',
  timezone: 'Europe/Minsk',
};
console.log(summaryBox(cfg));
console.log(
  warningBox(
    `Диск ${cfg.disk} будет ПОЛНОСТЬЮ ОЧИЩЕН,\n` +
      'разбит по схеме disko.nix (ESP + LUKS → btrfs subvolumes),\n' +
      'и на него будет установлен NixOS c этим репозиторием.',
  ),
);
console.log(
  promptLine("Введи 'YES' для продолжения:", 'заглавными', 'YES'),
);
await sleep(700);

// --- 5. Disko (эмуляция стриминга) --------------------------------------
console.log(stepHeader(4, 8, `Disko: разметка и шифрование ${cfg.disk}`));
for (const line of [
  'wiping existing partitions on /dev/nvme0n1',
  'creating GPT partition table',
  'creating ESP partition (1G, FAT32)',
  'creating luks partition (100%)',
  'cryptsetup luksFormat --type luks2 /dev/nvme0n1p2',
  'opening luks container as /dev/mapper/crypted',
  'formatting btrfs on /dev/mapper/crypted',
  'creating subvolumes: root, home, nix, swap',
  'mounting /mnt (root subvolume, zstd compression)',
  'mounting /mnt/boot, /mnt/home, /mnt/nix, /mnt/.swapvol',
]) {
  console.log('  ' + chalk.gray(line));
  await sleep(60);
}

// --- 6. Копирование конфига ---------------------------------------------
console.log(stepHeader(5, 8, 'Копирование конфига в /mnt/etc/nixos'));
console.log(c.ok('  ✓ Конфиг скопирован в /mnt/etc/nixos'));
await sleep(300);

console.log(stepHeader(6, 8, 'Генерация hardware-configuration.nix'));
for (const line of [
  'writing /mnt/etc/nixos/hardware-configuration.nix',
  'detected initrd modules: xhci_pci, nvme, ahci, usb_storage, usbhid, sd_mod',
  'detected filesystems: btrfs on /dev/mapper/crypted, vfat on /dev/nvme0n1p1',
  'detected LUKS device: /dev/nvme0n1p2 → crypted',
]) {
  console.log('  ' + chalk.gray(line));
  await sleep(60);
}
await sleep(300);

// --- 7. nixos-install (много строк, серый) -----------------------------
console.log(stepHeader(7, 8, 'nixos-install (может занять 20-60 минут)'));
const fakePkgs = [
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-glibc-2.40\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-linux-6.18.44\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-systemd-256.16\' from cache.nixos.org...',
  'building \'/nix/store/xxxxxxxxxxxxxxxxxx-initrd-linux-6.18.44.drv\'...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-nvidia-x11-595.45.04\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-mesa-25.1.0\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-niri-0.1.10\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-noctalia-shell-4.7.7\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-vesktop-1.5.6\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-librewolf-153.0.4-1\' from cache.nixos.org...',
  'copying path \'/nix/store/xxxxxxxxxxxxxxxxxx-steam-1.0.0.87\' from cache.nixos.org...',
  'building \'/nix/store/xxxxxxxxxxxxxxxxxx-nixos-system-workstation.drv\'...',
  'updating GRUB 2 menu...',
  'activating the configuration...',
  'setting up /etc...',
  'reloading user units for alice...',
  'Done. The new configuration is /nix/store/xxxxx-nixos-system-workstation-26.11',
];
for (const line of fakePkgs) {
  console.log('  ' + chalk.gray(line));
  await sleep(80);
}
await sleep(300);

// --- 8. passwd (эмуляция) -----------------------------------------------
console.log(stepHeader(8, 8, `Пароль для ${cfg.username}`));
console.log(c.dim('  Установи пароль в chroot:'));
console.log('  ' + chalk.gray('New password:') + chalk.dim(' ••••••••'));
console.log('  ' + chalk.gray('Retype new password:') + chalk.dim(' ••••••••'));
console.log('  ' + chalk.gray('passwd: password updated successfully'));
await sleep(300);

// --- 9. Успех -----------------------------------------------------------
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
console.log(
  promptLine('Перезагрузиться сейчас?', 'да / нет', chalk.yellow('нет')),
);
console.log(
  '\n' + c.dim('  [ демо-режим — реальная установка не выполнялась ]') + '\n',
);
