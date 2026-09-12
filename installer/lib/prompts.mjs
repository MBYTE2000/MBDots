// Интерактивные шаги. Все — обёртки над `prompts`, чтобы централизованно
// обрабатывать Ctrl-C (пользователь прервал — мы выходим с ненулевым кодом,
// не с половинной установкой).
import prompts from 'prompts';
import chalk from 'chalk';
import { c } from './branding.mjs';
import { listDisks } from './util.mjs';

function onCancel() {
  console.log('\n' + c.err('Отменено пользователем.'));
  process.exit(130);
}

const opts = { onCancel };

const HOSTNAME_RE = /^[a-zA-Z][a-zA-Z0-9-]{0,62}$/;
const USERNAME_RE = /^[a-z_][a-z0-9_-]{0,31}$/;
const TIMEZONES = [
  'Europe/Minsk',
  'Europe/Moscow',
  'Europe/Warsaw',
  'Europe/Berlin',
  'Europe/London',
  'Europe/Kyiv',
  'Asia/Almaty',
  'Asia/Tbilisi',
  'Asia/Yerevan',
  'Asia/Tashkent',
  'UTC',
];

export async function askDisk() {
  const disks = await listDisks();
  if (disks.length === 0)
    throw new Error('Не найдено ни одного диска (lsblk -d).');

  const choices = disks.map((d) => {
    const badges = [
      d.transport,
      d.removable ? chalk.yellow('removable') : null,
      d.readonly ? chalk.red('ro') : null,
      d.mounted ? chalk.red('mounted') : null,
    ]
      .filter(Boolean)
      .join(' ');
    return {
      title: `${d.path.padEnd(16)} ${chalk.bold(d.size.padStart(8))}  ${
        d.model || chalk.gray('(без модели)')
      }`,
      description: badges,
      value: d.path,
      disabled: d.readonly,
    };
  });

  const { disk } = await prompts(
    {
      type: 'select',
      name: 'disk',
      message: 'Выбери целевой диск (данные будут стёрты):',
      choices,
      hint: 'стрелки ↑↓, Enter — выбрать',
    },
    opts,
  );
  return disk;
}

export async function askHostname(defaultVal = 'nixos') {
  const { hostname } = await prompts(
    {
      type: 'text',
      name: 'hostname',
      message: 'Hostname (буквы/цифры/дефис, начинается с буквы):',
      initial: defaultVal,
      validate: (v) =>
        HOSTNAME_RE.test(v.trim()) || 'Невалидный hostname',
      format: (v) => v.trim(),
    },
    opts,
  );
  return hostname;
}

export async function askUsername(defaultVal = 'mbyte') {
  const { username } = await prompts(
    {
      type: 'text',
      name: 'username',
      message: 'Имя основного пользователя:',
      initial: defaultVal,
      validate: (v) =>
        USERNAME_RE.test(v.trim()) ||
        'Строчные буквы/цифры/дефис/подчёркивание, начинается с буквы или _',
      format: (v) => v.trim(),
    },
    opts,
  );
  return username;
}

export async function askGpu() {
  const { gpu } = await prompts(
    {
      type: 'select',
      name: 'gpu',
      message: 'GPU-профиль:',
      choices: [
        {
          title: 'NVIDIA',
          description: 'проприетарный драйвер (nvidiaPackages.beta)',
          value: 'nvidia',
        },
        {
          title: 'AMD',
          description: 'amdgpu / mesa',
          value: 'amd',
        },
        {
          title: 'Intel',
          description: 'i965/iHD, VAAPI',
          value: 'intel',
        },
        {
          title: 'None',
          description: 'без отдельного GPU (VM/сервер)',
          value: 'none',
        },
      ],
      initial: 0,
    },
    opts,
  );
  return gpu;
}

export async function askTimezone() {
  const { timezone } = await prompts(
    {
      type: 'autocomplete',
      name: 'timezone',
      message: 'Timezone (набирай для фильтра):',
      choices: TIMEZONES.map((tz) => ({ title: tz, value: tz })),
      initial: 0,
      suggest: (input, choices) =>
        Promise.resolve(
          choices.filter((ch) =>
            ch.title.toLowerCase().includes(input.toLowerCase()),
          ),
        ),
    },
    opts,
  );
  return timezone;
}

export async function askLuksPassword() {
  while (true) {
    const { p1 } = await prompts(
      {
        type: 'password',
        name: 'p1',
        message: 'LUKS-пароль (диск будет зашифрован):',
        validate: (v) =>
          v.length >= 6 || 'Минимум 6 символов',
      },
      opts,
    );
    const { p2 } = await prompts(
      {
        type: 'password',
        name: 'p2',
        message: 'Повтори пароль:',
      },
      opts,
    );
    if (p1 === p2) return p1;
    console.log(c.err('  Пароли не совпадают, попробуй снова.'));
  }
}

export async function confirmWipe(cfg) {
  const { ok } = await prompts(
    {
      type: 'text',
      name: 'ok',
      message: `Всё содержимое ${cfg.disk} будет уничтожено. Введи '${chalk.red.bold('YES')}' для продолжения:`,
      validate: (v) =>
        v === 'YES' ||
        'Точно YES заглавными, если действительно хочешь продолжить',
    },
    opts,
  );
  return ok === 'YES';
}

export async function confirmReboot() {
  const { r } = await prompts(
    {
      type: 'toggle',
      name: 'r',
      message: 'Перезагрузиться сейчас?',
      initial: false,
      active: 'да',
      inactive: 'нет',
    },
    opts,
  );
  return r;
}
