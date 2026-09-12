// Мелкие утилиты: запуск процессов, проверка окружения, чтение блочных устройств.
import { execa } from 'execa';
import { existsSync } from 'fs';
import chalk from 'chalk';
import { c } from './branding.mjs';

// Запустить команду и вернуть stdout (без стрима, без TUI).
export async function sh(cmd, args = [], opts = {}) {
  const res = await execa(cmd, args, { reject: false, ...opts });
  if (res.exitCode !== 0 && !opts.allowFail) {
    throw new Error(
      `Команда ${cmd} ${args.join(' ')} упала (exit ${res.exitCode}):\n${res.stderr || res.stdout}`,
    );
  }
  return res.stdout;
}

// Запустить с потоковым выводом, окрашивая строки в тусклый цвет.
// Возвращает промис, который резолвится по exit 0 или реджектится.
export function shStream(cmd, args = [], opts = {}) {
  return new Promise((resolve, reject) => {
    const subprocess = execa(cmd, args, {
      stdio: ['inherit', 'pipe', 'pipe'],
      ...opts,
    });
    const pipe = (stream, tint) => {
      let buf = '';
      stream.on('data', (chunk) => {
        buf += chunk.toString();
        let idx;
        while ((idx = buf.indexOf('\n')) !== -1) {
          const line = buf.slice(0, idx);
          buf = buf.slice(idx + 1);
          process.stdout.write('  ' + tint(line) + '\n');
        }
      });
      stream.on('end', () => {
        if (buf.length) process.stdout.write('  ' + tint(buf) + '\n');
      });
    };
    pipe(subprocess.stdout, chalk.gray);
    pipe(subprocess.stderr, chalk.hex('#FFB454'));
    subprocess.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${cmd} exit ${code}`));
    });
    subprocess.on('error', reject);
  });
}

// Список блочных устройств.
export async function listDisks() {
  const raw = await sh('lsblk', [
    '-J',
    '-o',
    'NAME,SIZE,MODEL,TYPE,MOUNTPOINT,RM,RO,TRAN',
    '-d',
  ]);
  const data = JSON.parse(raw);
  return data.blockdevices
    .filter((d) => d.type === 'disk')
    .map((d) => ({
      path: '/dev/' + d.name,
      size: d.size,
      model: (d.model || '').trim(),
      transport: (d.tran || '').toUpperCase(),
      removable: d.rm === true || d.rm === '1',
      readonly: d.ro === true || d.ro === '1',
      mounted: !!d.mountpoint,
    }));
}

// Предполётные проверки: root, необходимые бинарники, интернет.
export async function preflight() {
  const results = [];
  const check = (label, ok, hint = '') =>
    results.push({ label, ok, hint });

  check('запуск от root', process.getuid && process.getuid() === 0);
  check(
    'nix в PATH',
    !!(await sh('sh', ['-c', 'command -v nix || true'])),
    'запусти с NixOS Live ISO',
  );
  check(
    'nixos-install в PATH',
    !!(await sh('sh', ['-c', 'command -v nixos-install || true'])),
    'запусти с NixOS Live ISO',
  );
  check('lsblk доступен', !!(await sh('sh', ['-c', 'command -v lsblk || true'])));
  check(
    'интернет (cache.nixos.org)',
    (await sh('sh', [
      '-c',
      'timeout 5 curl -sSf https://cache.nixos.org/nix-cache-info >/dev/null && echo ok || echo no',
    ])) === 'ok',
    'нужен доступ в интернет для установки',
  );

  return results;
}

export function renderChecks(results) {
  const out = results
    .map((r) => {
      const icon = r.ok ? c.ok('✓') : c.err('✗');
      const hint = !r.ok && r.hint ? c.dim(' — ' + r.hint) : '';
      return `  ${icon}  ${r.label}${hint}`;
    })
    .join('\n');
  return out + '\n';
}

export function requireRepo(repoPath) {
  const mustHave = [
    'flake.nix',
    'disko.nix',
    'hosts/nixos/default.nix',
    'modules/core/networking.nix',
    'modules/core/users.nix',
    'home/base.nix',
    'gpu/nvidia.nix',
    'gpu/amd.nix',
    'gpu/intel.nix',
    'gpu/none.nix',
  ];
  const missing = mustHave.filter((f) => !existsSync(`${repoPath}/${f}`));
  if (missing.length) {
    throw new Error(
      'Репозиторий не похож на MBDots (отсутствуют: ' +
        missing.join(', ') +
        '). Проверь путь: ' +
        repoPath,
    );
  }
}
