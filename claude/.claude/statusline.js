#!/usr/bin/env node
// Claude Code statusline — una sola línea, con iconos Nerd Font y paleta Nord.
//
//    ruta    rama ✗  │   modelo  │   ctx 42%/1M  │   5h 16% ⟳01:13  7d 65% ⟳jue 12:33
//
// Cada icono va seguido de un espacio (el glifo se dibuja ocupando esa celda) y
// los segmentos se separan con "  │  ", para que nada quede pegado ni encima.
// Verde < 60 %, naranja >= 60 %, rojo >= 80 % de lo consumido (ctx, 5h y 7d).

const { spawnSync } = require('child_process');

const chunks = [];
process.stdin.on('data', d => chunks.push(d));
process.stdin.on('end', () => {
  let data = {};
  try { data = JSON.parse(Buffer.concat(chunks).toString()); } catch (_) {}

  // ── Colores (Nord, truecolor) ──────────────────────────────────────────────
  const c = (r, g, b) => `\x1b[38;2;${r};${g};${b}m`;
  const RESET = '\x1b[0m';
  const DIM   = '\x1b[2m';
  const CYAN   = c(136, 192, 208);   // ruta
  const PURPLE = c(180, 142, 173);   // rama
  const YELLOW = c(235, 203, 139);   // cambios sin commitear
  const BLUE   = c(129, 161, 193);   // modelo
  const TEXT   = c(216, 222, 233);
  const GREEN  = c(163, 190, 140);
  const ORANGE = c(208, 135, 112);
  const RED    = c(191, 97, 106);

  // ── Iconos Nerd Font (por código, para no depender de la codificación) ─────
  const I = {
    folder: '', branch: '', model: '',
    ctx: '', clock: '',
  };
  const seg = (color, icon, text) => `${color}${icon} ${RESET}${TEXT}${text}${RESET}`;
  const SEP = `  ${DIM}│${RESET}  `;

  // ── Datos ──────────────────────────────────────────────────────────────────
  const cwd  = data?.workspace?.current_dir ?? data?.cwd ?? process.cwd();
  const home = process.env.HOME || process.env.USERPROFILE || '';
  let p = (cwd || '').replace(/\\/g, '/');
  const h = home.replace(/\\/g, '/');
  if (h && p.toLowerCase().startsWith(h.toLowerCase())) p = '~' + p.slice(h.length);
  const parts = p.split('/').filter(Boolean);
  const shortPath = parts.length > 3 ? '…/' + parts.slice(-3).join('/') : p;

  const model   = data?.model?.display_name ?? data?.model?.id ?? 'Claude';
  const usedPct = data?.context_window?.used_percentage;
  const ctxSize = data?.context_window?.context_window_size;
  const vimMode = data?.vim?.mode ?? null;
  const rl      = data?.rate_limits;

  function git(args) {
    const r = spawnSync('git', ['-C', cwd, ...args], { encoding: 'utf8', timeout: 800 });
    return r.status === 0 && r.stdout ? r.stdout.trim() : null;
  }
  let branch = data?.worktree?.branch ?? git(['rev-parse', '--abbrev-ref', 'HEAD']);
  if (branch === 'HEAD') {
    const sha = git(['rev-parse', '--short', 'HEAD']);
    branch = sha ? `detached@${sha}` : null;
  }
  const dirty = branch ? !!git(['status', '--porcelain']) : false;

  const pct   = v => Math.max(0, Math.min(100, Math.round(v)));
  const color = n => (n >= 80 ? RED : n >= 60 ? ORANGE : GREEN);

  // Hora absoluta del reset (una cuenta atrás se quedaría vieja entre repintados).
  function resetAt(epochSec) {
    if (!epochSec) return '';
    const d = new Date(epochSec * 1000);
    if (Number.isNaN(d.getTime())) return '';
    const hhmm = d.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', hour12: false });
    const day  = x => new Date(x.getFullYear(), x.getMonth(), x.getDate());
    const days = Math.round((day(d) - day(new Date())) / 86400000);
    if (days <= 0) return hhmm;
    if (days < 7) {
      return `${d.toLocaleDateString('es-ES', { weekday: 'short' }).replace('.', '').slice(0, 3)} ${hhmm}`;
    }
    return `${d.getDate()}/${d.getMonth() + 1} ${hhmm}`;
  }

  // ── Segmentos ──────────────────────────────────────────────────────────────
  const out = [];

  let first = `${CYAN}${I.folder} ${RESET}${CYAN}${shortPath}${RESET}`;
  if (branch) {
    first += `  ${PURPLE}${I.branch} ${branch}${RESET}`;
    if (dirty) first += ` ${YELLOW}✗${RESET}`;
  }
  if (vimMode) first += `  ${DIM}[${vimMode}]${RESET}`;
  out.push(first);

  out.push(`${BLUE}${I.model} ${RESET}${TEXT}${model}${RESET}`);

  if (usedPct != null) {
    const n = pct(usedPct);
    const size = !ctxSize ? '' : ctxSize >= 1e6 ? `/${+(ctxSize / 1e6).toFixed(1)}M` : `/${Math.round(ctxSize / 1000)}k`;
    out.push(`${color(n)}${I.ctx} ${RESET}${TEXT}ctx ${RESET}${color(n)}${n}%${RESET}${DIM}${size}${RESET}`);
  }

  const quota = [['5h', rl?.five_hour], ['7d', rl?.seven_day]].flatMap(([label, w]) => {
    if (!w || typeof w.used_percentage !== 'number' || !Number.isFinite(w.used_percentage)) return [];
    const n = pct(w.used_percentage);
    const at = resetAt(w.resets_at);
    return [`${TEXT}${label} ${RESET}${color(n)}${n}%${RESET}${at ? ` ${DIM}⟳ ${at}${RESET}` : ''}`];
  });
  if (quota.length) out.push(`${YELLOW}${I.clock} ${RESET}${quota.join('   ')}`);

  process.stdout.write(out.join(SEP) + '\n');
});
