// Шаги установки — патчим рабочую копию конфига и запускаем disko/nixos-install.
import {
  existsSync, mkdirSync, readFileSync, writeFileSync, cpSync, chmodSync, rmSync,
} from 'fs';
import { join } from 'path';
import { execa } from 'execa';
import ora from 'ora';
import { sh, shStream } from './util.mjs';
import { stepHeader, c } from './branding.mjs';

// Точечная подмена подстроки в файле (с проверкой что она там есть).
function patchFile(path, patterns) {
  let src = readFileSync(path, 'utf8');
  for (const [needle, replacement] of patterns) {
    const isRegex = needle instanceof RegExp;
    if (!isRegex && !src.includes(needle)) {
      throw new Error(`patchFile ${path}: не найдено: ${String(needle).slice(0, 80)}`);
    }
    src = isRegex ? src.replace(needle, replacement) : src.split(needle).join(replacement);
  }
  writeFileSync(path, src);
}

export async function prepareWorkdir(repoPath) {
  const work = await sh('mktemp', ['-d', '-t', 'mbdots-XXXXXX']);
  cpSync(repoPath, work, { recursive: true, verbatimSymlinks: false });
  return work;
}

// --- Patches --------------------------------------------------------------
export function applyProfile(work, cfg) {
  const OLD_HOST = 'nixos';
  const OLD_USER = 'mbyte';
  const OLD_TZ = 'Europe/Minsk';

  // flake.nix
  patchFile(join(work, 'flake.nix'), [
    [`nixosConfigurations.${OLD_HOST} =`, `nixosConfigurations.${cfg.hostname} =`],
    [`users.${OLD_USER} = {`, `users.${cfg.username} = {`],
  ]);

  // modules/core/networking.nix: hostname + static/dhcp + aliases
  const netPath = join(work, 'modules/core/networking.nix');
  let netSrc = readFileSync(netPath, 'utf8');
  // 1) hostname
  netSrc = netSrc.replace(
    /networking\.hostName = "[^"]*";/,
    `networking.hostName = "${cfg.hostname}";`,
  );
  // 2) интерфейс (у нас всегда ensureProfiles.profiles.ethPort — туда и пишем)
  if (cfg.network.mode === 'static') {
    netSrc = netSrc.replace(
      /interface-name = "[^"]+";/,
      `interface-name = "${cfg.network.interface}";`,
    );
    netSrc = netSrc.replace(
      /address1 = "[^"]+";/,
      `address1 = "${cfg.network.address},${cfg.network.gateway}";`,
    );
    netSrc = netSrc.replace(
      /dns = "[^"]+";/,
      `dns = "${cfg.network.dns.join(';')}";`,
    );
  } else {
    // DHCP: удаляем ensureProfiles блок (оставляем только networkmanager.enable)
    netSrc = netSrc.replace(
      /networking\.networkmanager\.ensureProfiles\.profiles = {[\s\S]*?^\s*};/m,
      '# DHCP: NetworkManager даст адрес сам.',
    );
  }
  // 3) hostname aliases через networking.hosts — вставляем ВНУТРЬ top-level
  // attrset (перед последней `}`), иначе получим syntax error в nix.
  if (cfg.aliases && cfg.aliases.length > 0) {
    const aliasesLine = cfg.aliases.map(a => `"${a}"`).join(' ');
    const insertion = `\n  networking.hosts."127.0.0.1" = [ ${aliasesLine} ];\n`;
    // Заменяем последнюю `\n}` (с опциональным whitespace) на insertion + `\n}`
    netSrc = netSrc.replace(/\n}\s*$/, insertion + '\n}\n');
  }
  writeFileSync(netPath, netSrc);

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

  // hosts/nixos/default.nix — выставить флаги категорий + сервисы + dataDisk
  const hostPath = join(work, 'hosts/nixos/default.nix');
  let hostSrc = readFileSync(hostPath, 'utf8');
  hostSrc = hostSrc.replace(
    /hardware\.dataDisk\.enable\s*=\s*(true|false);/,
    `hardware.dataDisk.enable = ${cfg.dataDisk ? 'true' : 'false'};`,
  );
  const catBlock = [
    '    categories = {',
    `      dev.enable        = ${cfg.categories.dev};`,
    `      gaming.enable     = ${cfg.categories.gaming};`,
    `      ai.enable         = ${cfg.categories.ai};`,
    `      multimedia.enable = ${cfg.categories.multimedia};`,
    `      office.enable     = ${cfg.categories.office};`,
    `      comms.enable      = ${cfg.categories.comms};`,
    `      fileshare.enable  = ${cfg.categories.fileshare};`,
    '    };',
  ].join('\n');
  hostSrc = hostSrc.replace(
    /    categories = {[\s\S]*?    };/,
    catBlock,
  );
  // ollama гейтится отдельно: если ai=true, включим сервис
  const ollamaOn = cfg.categories.ai ? 'true' : 'false';
  hostSrc = hostSrc.replace(
    /ollama\.enable\s*=\s*(true|false);/,
    `ollama.enable   = ${ollamaOn};`,
  );
  writeFileSync(hostPath, hostSrc);
}

export function applyGpuProfile(work, gpu) {
  const src = join(work, `gpu/${gpu}.nix`);
  const dst = join(work, 'gpu/current.nix');
  if (!existsSync(src)) throw new Error(`gpu/${gpu}.nix не найден`);
  cpSync(src, dst);
}

// --- LUKS -----------------------------------------------------------------
const LUKS_PWFILE = '/tmp/mbdots-luks-password';
export function stageLuksPassword(work, password) {
  writeFileSync(LUKS_PWFILE, password, { mode: 0o600 });
  chmodSync(LUKS_PWFILE, 0o600);
  const p = join(work, 'disko.nix');
  const src = readFileSync(p, 'utf8');
  const marker = 'name = "crypted";';
  if (!src.includes(marker)) throw new Error('disko.nix: не нашёл блок luks');
  const patched = src.replace(
    marker,
    `${marker}\n              passwordFile = "${LUKS_PWFILE}";`,
  );
  writeFileSync(p, patched);
}

export function clearLuksPassword(work) {
  try { rmSync(LUKS_PWFILE, { force: true }); } catch {}
  const p = join(work, 'disko.nix');
  const src = readFileSync(p, 'utf8');
  writeFileSync(
    p,
    src.split('\n')
       .filter(l => !l.includes(`passwordFile = "${LUKS_PWFILE}"`))
       .join('\n'),
  );
}

// --- Disko / install / dotfiles ------------------------------------------
export async function runDisko(work, disk) {
  console.log(stepHeader(5, 10, `Disko: разметка и шифрование ${disk}`));
  await shStream('nix', [
    '--experimental-features', 'nix-command flakes',
    'run', 'github:nix-community/disko/latest', '--',
    '--mode', 'destroy,format,mount',
    '--argstr', 'disk', disk,
    join(work, 'disko.nix'),
  ]);
}

export function copyConfigToTarget(work) {
  const target = '/mnt/etc/nixos';
  mkdirSync(target, { recursive: true });
  cpSync(work, target, {
    recursive: true,
    filter: (src) => !/\/(\.git|node_modules|result|result-.*)$/.test(src),
  });
}

export async function generateHardwareConfig() {
  console.log(stepHeader(7, 10, 'Генерация hardware-configuration.nix'));
  await shStream('nixos-generate-config', ['--root', '/mnt', '--force']);
}

export async function runNixosInstall(cfg) {
  console.log(stepHeader(8, 10, 'nixos-install (20-60 минут)'));
  await shStream('nixos-install', [
    '--root', '/mnt',
    '--flake', `/mnt/etc/nixos#${cfg.hostname}`,
    '--no-root-passwd',
  ]);
}

export function installUserDotfiles(work, username) {
  const src = join(work, 'config');
  if (!existsSync(src)) return false;
  const home = `/mnt/home/${username}`;
  mkdirSync(`${home}/.config`, { recursive: true });
  cpSync(src, `${home}/.config`, { recursive: true });
  return true;
}

export async function chownUserHome(username) {
  await execa('sh', ['-c',
    `chown -R $(awk -F: -v u=${username} '$1==u{print $3":"$4}' /mnt/etc/passwd) /mnt/home/${username}`,
  ]);
}

export async function setUserPassword(username) {
  console.log(stepHeader(10, 10, `Пароль для ${username}`));
  console.log(c.dim('  Пароль задаётся в chroot:'));
  await execa('nixos-enter', ['--root', '/mnt', '-c', `passwd ${username}`], { stdio: 'inherit' });
}

export function copyToRepoHome(work, username) {
  const home = `/mnt/home/${username}`;
  const repoDst = `${home}/nixos-config`;
  cpSync(work, repoDst, {
    recursive: true,
    filter: (src) => !/\/(\.git|node_modules|result|result-.*)$/.test(src),
  });
  try { rmSync('/mnt/etc/nixos', { recursive: true, force: true }); } catch {}
  return execa('ln', ['-sfn', `/home/${username}/nixos-config`, '/mnt/etc/nixos']);
}
