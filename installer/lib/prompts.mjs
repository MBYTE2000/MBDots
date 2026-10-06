// Интерактивные промпты установщика. Все обёрнуты в onCancel → exit(130),
// чтобы Ctrl-C не оставлял установку в полу-состоянии.
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
const CIDR_RE     = /^((\d{1,3}\.){3}\d{1,3})\/\d{1,2}$/;
const IP_RE       = /^(\d{1,3}\.){3}\d{1,3}$/;
const TIMEZONES = [
  'Europe/Minsk', 'Europe/Moscow', 'Europe/Warsaw', 'Europe/Berlin',
  'Europe/London', 'Europe/Kyiv', 'Asia/Almaty', 'Asia/Tbilisi',
  'Asia/Yerevan', 'Asia/Tashkent', 'UTC',
];

// --- Диск -----------------------------------------------------------------
export async function askDisk() {
  const disks = await listDisks();
  if (disks.length === 0) throw new Error('Нет дисков (lsblk -d).');

  const choices = disks.map((d) => {
    const badges = [
      d.transport,
      d.removable ? chalk.yellow('removable') : null,
      d.readonly ? chalk.red('ro') : null,
      d.mounted ? chalk.red('mounted') : null,
    ].filter(Boolean).join(' ');
    return {
      title: `${d.path.padEnd(16)} ${chalk.bold(d.size.padStart(8))}  ${d.model || chalk.gray('(без модели)')}`,
      description: badges,
      value: d.path,
      disabled: d.readonly,
    };
  });

  const { disk } = await prompts({
    type: 'select', name: 'disk',
    message: 'Целевой диск (ДАННЫЕ БУДУТ СТЁРТЫ):',
    choices, hint: '↑↓ выбор, Enter подтвердить',
  }, opts);
  return disk;
}

// --- Hostname + aliases ---------------------------------------------------
export async function askHostnameAndAliases(defaultHost = 'nixos') {
  const { hostname } = await prompts({
    type: 'text', name: 'hostname',
    message: 'Hostname:',
    initial: defaultHost,
    validate: v => HOSTNAME_RE.test(v.trim()) || 'Невалидный hostname',
    format: v => v.trim(),
  }, opts);

  const { aliasesStr } = await prompts({
    type: 'text', name: 'aliasesStr',
    message: `Дополнительные алиасы (через запятую, пример: "${hostname}.local, pc"):`,
    initial: `${hostname}.local`,
    format: v => v.trim(),
  }, opts);

  const aliases = (aliasesStr || '')
    .split(',').map(s => s.trim()).filter(Boolean);
  return { hostname, aliases };
}

// --- Username -------------------------------------------------------------
export async function askUsername(defaultVal = 'mbyte') {
  const { username } = await prompts({
    type: 'text', name: 'username',
    message: 'Основной пользователь:',
    initial: defaultVal,
    validate: v => USERNAME_RE.test(v.trim()) ||
      'Строчные буквы/цифры/дефис/подчёркивание, первый — буква или _',
    format: v => v.trim(),
  }, opts);
  return username;
}

// --- GPU ------------------------------------------------------------------
export async function askGpu() {
  const { gpu } = await prompts({
    type: 'select', name: 'gpu', message: 'GPU-профиль:',
    choices: [
      { title: 'NVIDIA', description: 'проприетарный драйвер (nvidiaPackages.beta)', value: 'nvidia' },
      { title: 'AMD',    description: 'amdgpu / mesa',                               value: 'amd' },
      { title: 'Intel',  description: 'i965/iHD, VAAPI',                             value: 'intel' },
      { title: 'None',   description: 'без отдельного GPU (VM/сервер)',              value: 'none' },
    ],
    initial: 0,
  }, opts);
  return gpu;
}

// --- Timezone -------------------------------------------------------------
export async function askTimezone() {
  const { timezone } = await prompts({
    type: 'autocomplete', name: 'timezone',
    message: 'Timezone (набирай для фильтра):',
    choices: TIMEZONES.map(tz => ({ title: tz, value: tz })),
    initial: 0,
    suggest: (input, choices) =>
      Promise.resolve(choices.filter(ch => ch.title.toLowerCase().includes(input.toLowerCase()))),
  }, opts);
  return timezone;
}

// --- Network: static (default) / dhcp -------------------------------------
export async function askNetwork() {
  const { mode } = await prompts({
    type: 'select', name: 'mode',
    message: 'Сеть:',
    choices: [
      { title: 'Статический IP', description: 'рекомендовано для домашней сети', value: 'static' },
      { title: 'DHCP',           description: 'автоматически от роутера',        value: 'dhcp' },
    ],
    initial: 0,  // static по умолчанию
  }, opts);

  if (mode === 'dhcp') {
    return { mode: 'dhcp' };
  }

  // static — спрашиваем параметры (у текущей машины: enp11s0, 10.20.0.10/16, gw/dns 10.20.0.1)
  const r = await prompts([
    {
      type: 'text', name: 'interface', message: 'Сетевой интерфейс:',
      initial: 'enp11s0',
      validate: v => v.trim().length > 0 || 'Пустое не годится',
    },
    {
      type: 'text', name: 'address', message: 'IP с маской (CIDR):',
      initial: '10.20.0.10/16',
      validate: v => CIDR_RE.test(v.trim()) || 'Формат: 10.20.0.10/16',
      format: v => v.trim(),
    },
    {
      type: 'text', name: 'gateway', message: 'Шлюз:',
      initial: '10.20.0.1',
      validate: v => IP_RE.test(v.trim()) || 'Формат: 10.20.0.1',
      format: v => v.trim(),
    },
    {
      type: 'text', name: 'dns', message: 'DNS (через запятую):',
      initial: '10.20.0.1',
      validate: v => v.split(',').every(x => IP_RE.test(x.trim())) || 'Список IP через запятую',
      format: v => v.trim(),
    },
  ], opts);
  return {
    mode: 'static',
    interface: r.interface.trim(),
    address: r.address,
    gateway: r.gateway,
    dns: r.dns.split(',').map(x => x.trim()).filter(Boolean),
  };
}

// --- Второй NVMe (вторичный диск под AI blobs / etc) --------------------
export async function askDataDisk() {
  const { enable } = await prompts({
    type: 'toggle', name: 'enable',
    message: 'У тебя есть вторичный NVMe под /mnt/data (ollama blobs/comfyui)?',
    initial: false,  // по умолчанию нет — single-disk install
    active: 'да', inactive: 'нет',
  }, opts);
  return enable;
}

// --- Категории ------------------------------------------------------------
const CATEGORIES = [
  { name: 'dev',        title: 'Dev',        description: 'nvim/texlive/rust/python/claude-code' },
  { name: 'gaming',     title: 'Gaming',     description: 'steam/proton-ge/lutris/launchers/gamescope' },
  { name: 'ai',         title: 'AI/ML',      description: 'ollama-cuda/huggingface/run-qwen' },
  { name: 'multimedia', title: 'Multimedia', description: 'gimp/kdenlive/vlc/chromium' },
  { name: 'office',     title: 'Office',     description: 'onlyoffice/okular' },
  { name: 'comms',      title: 'Comms',      description: 'vesktop (discord)/materialgram (tg)' },
  { name: 'fileshare',  title: 'Fileshare',  description: 'qbittorrent' },
];

export async function askCategories() {
  const { mode } = await prompts({
    type: 'select', name: 'mode',
    message: 'Что ставим?',
    choices: [
      { title: 'Полный конфиг (все категории)',       value: 'all' },
      { title: 'Выбрать категории вручную',           value: 'pick' },
      { title: 'Минимум (только base + desktop)',     value: 'minimal' },
    ],
    initial: 0,
  }, opts);

  if (mode === 'all') {
    return Object.fromEntries(CATEGORIES.map(c => [c.name, true]));
  }
  if (mode === 'minimal') {
    return Object.fromEntries(CATEGORIES.map(c => [c.name, false]));
  }

  // pick: multiselect с чекбоксами
  const { picked } = await prompts({
    type: 'multiselect', name: 'picked',
    message: 'Отметь нужные (пробел — переключить, Enter — подтвердить, A — все):',
    choices: CATEGORIES.map(cat => ({
      title: cat.title,
      description: cat.description,
      value: cat.name,
      selected: true,  // по умолчанию все отмечены
    })),
    hint: '— использовать Space для toggle, A для «все/никто»',
    instructions: false,
    min: 0,
  }, opts);

  return Object.fromEntries(
    CATEGORIES.map(cat => [cat.name, (picked || []).includes(cat.name)]),
  );
}

// --- LUKS -----------------------------------------------------------------
export async function askLuksPassword() {
  while (true) {
    const { p1 } = await prompts({
      type: 'password', name: 'p1',
      message: 'LUKS-пароль:',
      validate: v => v.length >= 6 || 'Минимум 6 символов',
    }, opts);
    const { p2 } = await prompts({
      type: 'password', name: 'p2', message: 'Повтор:',
    }, opts);
    if (p1 === p2) return p1;
    console.log(c.err('  Пароли не совпадают, ещё раз.'));
  }
}

// --- Финальное подтверждение ---------------------------------------------
export async function confirmWipe(cfg) {
  const { ok } = await prompts({
    type: 'text', name: 'ok',
    message: `Введи ${chalk.red.bold("'YES'")} чтобы стереть ${cfg.disk}:`,
    validate: v => v === 'YES' || "Введи именно 'YES' заглавными",
  }, opts);
  return ok === 'YES';
}

export async function confirmReboot() {
  const { r } = await prompts({
    type: 'toggle', name: 'r',
    message: 'Перезагрузиться сейчас?',
    initial: false, active: 'да', inactive: 'нет',
  }, opts);
  return r;
}
