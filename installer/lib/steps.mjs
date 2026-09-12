// Шаги установки — модифицируют рабочую копию конфига, запускают disko и
// nixos-install. Каждый шаг возвращает promise; ошибки пробрасываются.
import { existsSync, mkdirSync, readFileSync, writeFileSync, cpSync, chmodSync, renameSync, rmSync } from 'fs';
import { join, dirname } from 'path';
import { execa } from 'execa';
import ora from 'ora';
import { sh, shStream } from './util.mjs';
import { stepHeader, c } from './branding.mjs';

// Атомарная замена подстроки в файле (с проверкой, что она там была).
function patchFile(path, patterns) {
  let src = readFileSync(path, 'utf8');
  for (const [needle, replacement] of patterns) {
    const isRegex = needle instanceof RegExp;
    if (!isRegex && !src.includes(needle)) {
      throw new Error(
        `patchFile ${path}: подстрока не найдена: ${needle.slice(0, 60)}`,
      );
    }
    src = isRegex ? src.replace(needle, replacement) : src.split(needle).join(replacement);
  }
  writeFileSync(path, src);
}

// Копия репо в /tmp — там мы правим hostname/username и подкладываем LUKS.
export async function prepareWorkdir(repoPath) {
  const work = await sh('mktemp', ['-d', '-t', 'mbdots-XXXXXX']);
  cpSync(repoPath, work, { recursive: true, verbatimSymlinks: false });
  return work;
}

// Подмена hostname/username/tz в конфиге dendritic-структуры.
export function applyProfile(work, cfg) {
  const OLD_HOST = 'nixos';
  const OLD_USER = 'mbyte';
  const OLD_TZ = 'Europe/Minsk';

  // flake.nix: nixosConfigurations.<host> + home-manager.users.<user>
  patchFile(join(work, 'flake.nix'), [
    [`nixosConfigurations.${OLD_HOST} =`, `nixosConfigurations.${cfg.hostname} =`],
    [`users.${OLD_USER} = {`, `users.${cfg.username} = {`],
  ]);

  // modules/core/networking.nix
  patchFile(join(work, 'modules/core/networking.nix'), [
    [`networking.hostName = "${OLD_HOST}";`, `networking.hostName = "${cfg.hostname}";`],
  ]);

  // modules/core/locale.nix
  patchFile(join(work, 'modules/core/locale.nix'), [
    [`time.timeZone = "${OLD_TZ}";`, `time.timeZone = "${cfg.timezone}";`],
  ]);

  // modules/core/users.nix
  patchFile(join(work, 'modules/core/users.nix'), [
    [`users.users.${OLD_USER} = {`, `users.users.${cfg.username} = {`],
  ]);

  // modules/programs/zsh.nix — update alias с хостом
  patchFile(join(work, 'modules/programs/zsh.nix'), [
    [`/etc/nixos#${OLD_HOST}`, `/etc/nixos#${cfg.hostname}`],
    [
      new RegExp(`nixos-rebuild switch --flake /etc/nixos#[^\"]*`),
      `nixos-rebuild switch --flake /etc/nixos#${cfg.hostname}`,
    ],
  ]);

  // home/base.nix
  patchFile(join(work, 'home/base.nix'), [
    [`home.username = "${OLD_USER}";`, `home.username = "${cfg.username}";`],
    [
      `home.homeDirectory = "/home/${OLD_USER}";`,
      `home.homeDirectory = "/home/${cfg.username}";`,
    ],
  ]);
}

// Активировать выбранный GPU-профиль → gpu/current.nix
export function applyGpuProfile(work, gpu) {
  const src = join(work, `gpu/${gpu}.nix`);
  const dst = join(work, 'gpu/current.nix');
  if (!existsSync(src))
    throw new Error(`gpu/${gpu}.nix не найден в рабочей копии`);
  cpSync(src, dst);
}

// Записать LUKS-пароль в файл (mode 600) и указать disko на него.
// Пароль стираем сразу после disko-run.
const LUKS_PWFILE = '/tmp/mbdots-luks-password';
export function stageLuksPassword(work, password) {
  writeFileSync(LUKS_PWFILE, password, { mode: 0o600 });
  chmodSync(LUKS_PWFILE, 0o600);
  // Вставляем `passwordFile = "...";` в блок luks в disko.nix.
  const p = join(work, 'disko.nix');
  const src = readFileSync(p, 'utf8');
  const marker = 'name = "crypted";';
  if (!src.includes(marker)) {
    throw new Error('disko.nix: не нашёл блок luks (name = "crypted";)');
  }
  const patched = src.replace(
    marker,
    `${marker}\n              passwordFile = "${LUKS_PWFILE}";`,
  );
  writeFileSync(p, patched);
}

export function clearLuksPassword(work) {
  try {
    rmSync(LUKS_PWFILE, { force: true });
  } catch {}
  // Убираем passwordFile из disko.nix, чтобы в /mnt не осталось ссылок на tmp.
  const p = join(work, 'disko.nix');
  const src = readFileSync(p, 'utf8');
  writeFileSync(
    p,
    src
      .split('\n')
      .filter((l) => !l.includes(`passwordFile = "${LUKS_PWFILE}"`))
      .join('\n'),
  );
}

// Запуск disko — разметка, шифрование, монтирование /mnt.
export async function runDisko(work, disk) {
  console.log(stepHeader(4, 8, `Disko: разметка и шифрование ${disk}`));
  await shStream('nix', [
    '--experimental-features',
    'nix-command flakes',
    'run',
    'github:nix-community/disko/latest',
    '--',
    '--mode',
    'destroy,format,mount',
    '--argstr',
    'disk',
    disk,
    join(work, 'disko.nix'),
  ]);
}

// Копирование конфига в /mnt/etc/nixos.
export function copyConfigToTarget(work) {
  const target = '/mnt/etc/nixos';
  mkdirSync(target, { recursive: true });
  cpSync(work, target, {
    recursive: true,
    filter: (src) => {
      // Не копируем .git, node_modules, result-*.
      return !/\/(\.git|node_modules|result|result-.*)$/.test(src);
    },
  });
}

// Генерация hardware-configuration.nix для целевого железа.
// Затирает наши файлы, поэтому вызываем ДО повторного копирования критичных мест.
export async function generateHardwareConfig() {
  console.log(stepHeader(6, 8, 'Генерация hardware-configuration.nix'));
  await shStream('nixos-generate-config', ['--root', '/mnt', '--force']);
}

// Запуск nixos-install (долгий шаг).
export async function runNixosInstall(cfg) {
  console.log(stepHeader(7, 8, 'nixos-install (может занять 20-60 минут)'));
  await shStream('nixos-install', [
    '--root',
    '/mnt',
    '--flake',
    `/mnt/etc/nixos#${cfg.hostname}`,
    '--no-root-passwd',
  ]);
}

// Копирование пользовательских dot-файлов из config/ в $HOME.
export function installUserDotfiles(work, username) {
  const src = join(work, 'config');
  if (!existsSync(src)) return false;
  const home = `/mnt/home/${username}`;
  mkdirSync(`${home}/.config`, { recursive: true });
  cpSync(src, `${home}/.config`, { recursive: true });
  return true;
}

// chown -R /home/<user> в chroot (внутри /mnt uid/gid только что созданы).
export async function chownUserHome(username) {
  await execa('sh', [
    '-c',
    `chown -R $(awk -F: -v u=${username} '$1==u{print $3":"$4}' /mnt/etc/passwd) /mnt/home/${username}`,
  ]);
}

// Установка пароля пользователя (интерактивно, через nixos-enter).
export async function setUserPassword(username) {
  console.log(stepHeader(8, 8, `Пароль для ${username}`));
  console.log(c.dim('  Установи пароль в chroot:'));
  await execa('nixos-enter', ['--root', '/mnt', '-c', `passwd ${username}`], {
    stdio: 'inherit',
  });
}

export function copyToRepoHome(work, username) {
  // Копируем актуальный (с патчами) репо в ~/nixos-config на новой машине,
  // чтобы /etc/nixos сразу был symlink на пользовательский git-репо (традиция).
  const home = `/mnt/home/${username}`;
  const repoDst = `${home}/nixos-config`;
  cpSync(work, repoDst, {
    recursive: true,
    filter: (src) => !/\/(\.git|node_modules|result|result-.*)$/.test(src),
  });
  // /etc/nixos → ~/nixos-config
  try {
    rmSync('/mnt/etc/nixos', { recursive: true, force: true });
  } catch {}
  // Реализуем symlink через exec — избегаем зависимости от точного JS API.
  return execa('ln', ['-sfn', `/home/${username}/nixos-config`, '/mnt/etc/nixos']);
}
