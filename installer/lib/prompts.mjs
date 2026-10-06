// Интерактивные промпты установщика. Все обёрнуты в onCancel → exit(130).
// Строки берутся из t: см. lib/i18n.mjs. Язык выбирается первым промптом.
import prompts from 'prompts';
import chalk from 'chalk';
import { c } from './branding.mjs';
import { listDisks } from './util.mjs';
import { LANGUAGES, STRINGS } from './i18n.mjs';

function makeCancel(msg) {
  return () => {
    console.log('\n' + c.err(msg));
    process.exit(130);
  };
}

const HOSTNAME_RE = /^[a-zA-Z][a-zA-Z0-9-]{0,62}$/;
const USERNAME_RE = /^[a-z_][a-z0-9_-]{0,31}$/;
const CIDR_RE     = /^((\d{1,3}\.){3}\d{1,3})\/\d{1,2}$/;
const IP_RE       = /^(\d{1,3}\.){3}\d{1,3}$/;
const TIMEZONES = [
  'Europe/Minsk', 'Europe/Moscow', 'Europe/Warsaw', 'Europe/Berlin',
  'Europe/London', 'Europe/Kyiv', 'Asia/Almaty', 'Asia/Tbilisi',
  'Asia/Yerevan', 'Asia/Tashkent', 'UTC',
];

// --- Language (ASCII-only, first prompt) ---------------------------------
export async function askLang() {
  const onCancel = () => { console.log('\nCancelled.'); process.exit(130); };
  const { lang } = await prompts({
    type: 'select', name: 'lang',
    message: 'Language / Yazyk:',
    choices: LANGUAGES.map(l => ({ title: l.label, value: l.value })),
    initial: 0,
  }, { onCancel });
  return lang;
}

// --- Диск -----------------------------------------------------------------
export async function askDisk(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const disks = await listDisks();
  if (disks.length === 0) throw new Error('No disks (lsblk -d).');

  const choices = disks.map((d) => {
    const badges = [
      d.transport,
      d.removable ? chalk.yellow('removable') : null,
      d.readonly ? chalk.red('ro') : null,
      d.mounted ? chalk.red('mounted') : null,
    ].filter(Boolean).join(' ');
    return {
      title: `${d.path.padEnd(16)} ${chalk.bold(d.size.padStart(8))}  ${d.model || chalk.gray('(no model)')}`,
      description: badges,
      value: d.path,
      disabled: d.readonly,
    };
  });

  const { disk } = await prompts({
    type: 'select', name: 'disk',
    message: t.pickDisk,
    choices, hint: t.pickDiskHint,
  }, opts);
  return disk;
}

// --- Hostname + aliases ---------------------------------------------------
export async function askHostnameAndAliases(t, defaultHost = 'nixos') {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { hostname } = await prompts({
    type: 'text', name: 'hostname',
    message: t.hostnameLabel,
    initial: defaultHost,
    validate: v => HOSTNAME_RE.test(v.trim()) || t.hostnameBad,
    format: v => v.trim(),
  }, opts);

  const { aliasesStr } = await prompts({
    type: 'text', name: 'aliasesStr',
    message: t.aliasesLabel,
    initial: `${hostname}.local`,
    format: v => v.trim(),
  }, opts);

  const aliases = (aliasesStr || '')
    .split(',').map(s => s.trim()).filter(Boolean);
  return { hostname, aliases };
}

// --- Username -------------------------------------------------------------
export async function askUsername(t, defaultVal = 'mbyte') {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { username } = await prompts({
    type: 'text', name: 'username',
    message: t.usernameLabel,
    initial: defaultVal,
    validate: v => USERNAME_RE.test(v.trim()) || t.usernameBad,
    format: v => v.trim(),
  }, opts);
  return username;
}

// --- GPU ------------------------------------------------------------------
export async function askGpu(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { gpu } = await prompts({
    type: 'select', name: 'gpu', message: t.gpuLabel,
    choices: [
      { title: 'NVIDIA', description: 'proprietary (nvidiaPackages.beta)', value: 'nvidia' },
      { title: 'AMD',    description: 'amdgpu / mesa',                     value: 'amd' },
      { title: 'Intel',  description: 'i965/iHD, VAAPI',                   value: 'intel' },
      { title: 'None',   description: 'no dedicated GPU (VM/server)',      value: 'none' },
    ],
    initial: 0,
  }, opts);
  return gpu;
}

// --- Timezone -------------------------------------------------------------
export async function askTimezone(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { timezone } = await prompts({
    type: 'autocomplete', name: 'timezone',
    message: t.tzLabel,
    choices: TIMEZONES.map(tz => ({ title: tz, value: tz })),
    initial: 0,
    suggest: (input, choices) =>
      Promise.resolve(choices.filter(ch => ch.title.toLowerCase().includes(input.toLowerCase()))),
  }, opts);
  return timezone;
}

// --- Network: static (default) / dhcp -------------------------------------
export async function askNetwork(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { mode } = await prompts({
    type: 'select', name: 'mode',
    message: t.netLabel,
    choices: [
      { title: t.netStatic, value: 'static' },
      { title: t.netDhcp,   value: 'dhcp' },
    ],
    initial: 0,
  }, opts);

  if (mode === 'dhcp') return { mode: 'dhcp' };

  const r = await prompts([
    {
      type: 'text', name: 'interface', message: t.ifaceLabel,
      initial: 'enp11s0',
      validate: v => v.trim().length > 0 || 'empty',
    },
    {
      type: 'text', name: 'address', message: t.cidrLabel,
      initial: '10.20.0.10/16',
      validate: v => CIDR_RE.test(v.trim()) || t.cidrBad,
      format: v => v.trim(),
    },
    {
      type: 'text', name: 'gateway', message: t.gwLabel,
      initial: '10.20.0.1',
      validate: v => IP_RE.test(v.trim()) || t.gwBad,
      format: v => v.trim(),
    },
    {
      type: 'text', name: 'dns', message: t.dnsLabel,
      initial: '10.20.0.1',
      validate: v => v.split(',').every(x => IP_RE.test(x.trim())) || t.dnsBad,
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

// --- Второй NVMe ----------------------------------------------------------
export async function askDataDisk(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { enable } = await prompts({
    type: 'toggle', name: 'enable',
    message: t.dataDiskLabel,
    initial: false,
    active: t.yes, inactive: t.no,
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

export async function askCategories(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { mode } = await prompts({
    type: 'select', name: 'mode', message: t.categoriesLabel,
    choices: [
      { title: t.catFull,    value: 'all' },
      { title: t.catPick,    value: 'pick' },
      { title: t.catMinimal, value: 'minimal' },
    ],
    initial: 0,
  }, opts);

  if (mode === 'all')     return Object.fromEntries(CATEGORIES.map(c => [c.name, true]));
  if (mode === 'minimal') return Object.fromEntries(CATEGORIES.map(c => [c.name, false]));

  const { picked } = await prompts({
    type: 'multiselect', name: 'picked',
    message: t.catMultiMsg,
    choices: CATEGORIES.map(cat => ({
      title: cat.title,
      description: cat.description,
      value: cat.name,
      selected: true,
    })),
    hint: t.catMultiHint,
    instructions: false,
    min: 0,
  }, opts);

  return Object.fromEntries(
    CATEGORIES.map(cat => [cat.name, (picked || []).includes(cat.name)]),
  );
}

// --- LUKS -----------------------------------------------------------------
export async function askLuksPassword(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  while (true) {
    const { p1 } = await prompts({
      type: 'password', name: 'p1',
      message: t.luksLabel,
      validate: v => v.length >= 6 || t.luksShort,
    }, opts);
    const { p2 } = await prompts({
      type: 'password', name: 'p2', message: t.luksRepeat,
    }, opts);
    if (p1 === p2) return p1;
    console.log(c.err(t.luksMismatch));
  }
}

// --- Финальное подтверждение ---------------------------------------------
export async function confirmWipe(t, cfg) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { ok } = await prompts({
    type: 'text', name: 'ok',
    message: t.wipeConfirm(cfg.disk),
    validate: v => v === 'YES' || t.wipeConfirmBad,
  }, opts);
  return ok === 'YES';
}

export async function confirmReboot(t) {
  const opts = { onCancel: makeCancel(t.cancelled) };
  const { r } = await prompts({
    type: 'toggle', name: 'r',
    message: t.rebootQuestion,
    initial: false, active: t.yes, inactive: t.no,
  }, opts);
  return r;
}
