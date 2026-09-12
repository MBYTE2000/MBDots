// Брендинг MBDots Installer: баннер, палитра, боксы.
import chalk from 'chalk';
import figlet from 'figlet';
import gradient from 'gradient-string';
import boxen from 'boxen';

export const VERSION = '0.1.0';
export const TAGLINE = 'NixOS installer • LUKS + btrfs • dendritic modules';

// Циано-мадженто-жёлтый градиент — фирменные цвета MBDots.
export const brandGradient = gradient(['#00E5FF', '#B15CFF', '#FFB454']);

// Полезные короткие раскраски.
export const c = {
  brand: (s) => brandGradient.multiline(s),
  header: (s) => chalk.hex('#00E5FF').bold(s),
  step: (s) => chalk.hex('#B15CFF').bold(s),
  ok: (s) => chalk.green.bold(s),
  warn: (s) => chalk.yellow.bold(s),
  err: (s) => chalk.red.bold(s),
  dim: (s) => chalk.gray(s),
  kv: (k, v) => chalk.hex('#B15CFF')(k.padEnd(14)) + chalk.bold(v),
};

export function banner() {
  const art = figlet.textSync('MBDots', {
    font: 'ANSI Shadow',
    horizontalLayout: 'default',
    verticalLayout: 'default',
  });
  const lines = art.split('\n');
  const painted = lines.map((l) => brandGradient(l)).join('\n');
  const footer =
    chalk.bold('installer') +
    chalk.gray(' v' + VERSION) +
    '\n' +
    chalk.gray(TAGLINE);
  return painted + '\n' + footer + '\n';
}

export function stepHeader(n, total, title) {
  const label = `┌── STEP ${n}/${total}`;
  const line = '─'.repeat(Math.max(0, 60 - label.length - title.length - 3));
  return (
    '\n' +
    c.step(label) +
    ' ' +
    chalk.bold(title) +
    ' ' +
    c.dim(line) +
    '\n'
  );
}

export function summaryBox(cfg) {
  const body = [
    c.kv('Диск:', cfg.disk),
    c.kv('Hostname:', cfg.hostname),
    c.kv('Пользователь:', cfg.username),
    c.kv('GPU:', cfg.gpu),
    c.kv('Timezone:', cfg.timezone),
    c.kv('LUKS:', '••••••••'),
  ].join('\n');
  return boxen(body, {
    padding: 1,
    margin: { top: 1, bottom: 1, left: 0, right: 0 },
    borderStyle: 'round',
    borderColor: '#B15CFF',
    title: chalk.bold('Параметры установки'),
    titleAlignment: 'center',
  });
}

export function warningBox(text) {
  return boxen(chalk.yellow.bold(text), {
    padding: 1,
    margin: { top: 1, bottom: 1, left: 0, right: 0 },
    borderStyle: 'double',
    borderColor: '#FFB454',
    title: '⚠  ВНИМАНИЕ',
    titleAlignment: 'center',
  });
}

export function successBox(text) {
  return boxen(chalk.green(text), {
    padding: 1,
    margin: { top: 1, bottom: 1, left: 0, right: 0 },
    borderStyle: 'round',
    borderColor: 'green',
    title: '✓  Готово',
    titleAlignment: 'center',
  });
}
