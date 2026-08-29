#!/usr/bin/env node
/**
 * Wachkladde-Sync – minimaler Sync-Server ohne Abhängigkeiten.
 *
 *   node server/server.js [--port 8080] [--data ./data]
 *
 * Endpunkte
 *   GET  /                 -> liefert wachkladde.html aus
 *   GET  /api/wer          -> {name, darfSchreiben} (wer bin ich, darf ich schreiben?)
 *   GET  /api/ops?since=N  -> {cursor, ops:[...]}  (Änderungen ab Cursor N)
 *   POST /api/ops          -> {ops:[...]}          (eigene Änderungen absenden)
 *   GET  /api/snapshot     -> vollständiger Zustand (Backup / Erstsynchronisation)
 *
 * Schreibrechte: server/rechte.json legt fest, wer schreiben darf. Den Benutzer
 * meldet ein vorgeschalteter Reverse Proxy im Header (Vorgabe: X-Remote-User).
 * Ohne Proxy und ohne rechte.json darf jeder schreiben - das ist die bisherige
 * Betriebsart für ein geschlossenes Netz.
 *
 * Modell: append-only Op-Log. Jede Op = {id, path, val, ts, by}.
 * Zusammenführung im Client per Last-Write-Wins je Feldpfad (Zeitstempel).
 * Der Server hält zusätzlich einen materialisierten Zustand für Snapshots/Backup.
 */
const http = require('http'), fs = require('fs'), path = require('path');

const arg = (n, d) => { const i = process.argv.indexOf('--' + n); return i > -1 ? process.argv[i + 1] : d; };
const PORT = +arg('port', 8080);
const DATA = path.resolve(arg('data', path.join(__dirname, 'data')));
const ROOT = path.join(__dirname, '..');
const OPS = path.join(DATA, 'ops.jsonl');
const SNAP = path.join(DATA, 'snapshot.json');
const RECHTE = path.resolve(arg('rechte', path.join(__dirname, 'rechte.json')));

fs.mkdirSync(DATA, { recursive: true });
if (!fs.existsSync(OPS)) fs.writeFileSync(OPS, '');

let log = fs.readFileSync(OPS, 'utf8').split('\n').filter(Boolean).map(JSON.parse);
let snapshot = fs.existsSync(SNAP) ? JSON.parse(fs.readFileSync(SNAP, 'utf8')) : {};

/* rechte.json: { offen, gruppe, schreiben:[...], zuordnung:{kennung:Name} }
   Der PowerShell-Server prueft "gruppe" direkt gegen das Active Directory.
   Dieser Node-Server steht hinter einem Reverse Proxy und bekommt die Gruppen
   des Benutzers als Kopfzeile (Vorgabe: X-Remote-Groups, kommagetrennt).      */
function rechte() {
  try { return JSON.parse(fs.readFileSync(RECHTE, 'utf8')); }
  catch (e) { return null; }
}
function benutzer(req) {
  const r = rechte();
  const k = (r && r.kopfzeile ? r.kopfzeile : 'x-remote-user').toLowerCase();
  const roh = req.headers[k] || '';
  return String(roh).split('\\').pop().trim();     // DOMAENE\Name -> Name
}
function darfSchreiben(req) {
  const r = rechte();
  if (!r || r.offen === true) return true;
  const n = benutzer(req).toLowerCase();
  if (!n) return false;
  if (r.gruppe) {
    const kopf = (r.gruppenKopfzeile || 'x-remote-groups').toLowerCase();
    const meine = String(req.headers[kopf] || '').split(',')
      .map(g => g.split('\\').pop().trim().toLowerCase()).filter(Boolean);
    if (meine.includes(String(r.gruppe).split('\\').pop().trim().toLowerCase())) return true;
  }
  if (Array.isArray(r.schreiben) &&
      r.schreiben.some(x => String(x).split('\\').pop().trim().toLowerCase() === n)) return true;
  if (!r.gruppe && !Array.isArray(r.schreiben)) return true;
  return false;
}
function kladdenname(req) {
  const r = rechte(), n = benutzer(req);
  if (!r || !r.zuordnung || !n) return n;
  const treffer = Object.keys(r.zuordnung).find(k => k.toLowerCase() === n.toLowerCase());
  return treffer ? r.zuordnung[treffer] : n;
}

const setPath = (obj, p, v) => {
  const ks = p.split('.'), last = ks.pop();
  let o = obj;
  for (const k of ks) { if (o[k] == null || typeof o[k] !== 'object') o[k] = {}; o = o[k]; }
  o[last] = v;
};

function commit(ops) {
  const fresh = [];
  const known = new Set(log.map(o => o.id));
  for (const op of ops) {
    if (!op || !op.path || known.has(op.id)) continue;   // idempotent: Doppel-Sendungen ignorieren
    fresh.push(op); known.add(op.id);
    setPath(snapshot, op.path, op.val);
  }
  if (fresh.length) {
    fs.appendFileSync(OPS, fresh.map(o => JSON.stringify(o)).join('\n') + '\n');
    log.push(...fresh);
    fs.writeFileSync(SNAP, JSON.stringify(snapshot));
  }
  return fresh.length;
}

const json = (res, code, body) => {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' });
  res.end(JSON.stringify(body));
};

http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x');
  if (req.method === 'OPTIONS') return json(res, 204, {});

  if (u.pathname === '/api/wer') {
    const darf = darfSchreiben(req);
    return json(res, 200, { kennung: benutzer(req) || null, name: kladdenname(req) || null,
      darfSchreiben: darf, rolle: darf ? 'dgl' : 'leser', rechteAktiv: !!rechte() });
  }
  if (u.pathname === '/api/ops' && req.method === 'GET') {
    const since = +u.searchParams.get('since') || 0;
    return json(res, 200, { cursor: log.length, ops: log.slice(since) });
  }
  if (u.pathname === '/api/ops' && req.method === 'POST') {
    if (!darfSchreiben(req))
      return json(res, 403, { error: 'keine Schreibberechtigung',
        name: benutzer(req) || null });
    let b = '';
    req.on('data', c => { b += c; if (b.length > 4e6) req.destroy(); });
    return req.on('end', () => {
      try {
        const n = commit(JSON.parse(b).ops || []);
        json(res, 200, { ok: true, accepted: n, cursor: log.length });
      } catch (e) { json(res, 400, { error: e.message }); }
    });
  }
  if (u.pathname === '/api/snapshot') return json(res, 200, snapshot);

  // statische Auslieferung der App
  const file = u.pathname === '/' ? 'wachkladde.html' : u.pathname.replace(/^\/+/, '');
  const p = path.join(ROOT, file);
  if (!p.startsWith(ROOT) || !fs.existsSync(p) || fs.statSync(p).isDirectory())
    return json(res, 404, { error: 'not found' });
  const type = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
    '.css': 'text/css' }[path.extname(p)] || 'application/octet-stream';
  res.writeHead(200, { 'Content-Type': type + '; charset=utf-8' });
  fs.createReadStream(p).pipe(res);
}).listen(PORT, () => {
  console.log(`Wachkladde-Sync läuft: http://localhost:${PORT}  (Daten: ${DATA})`);
});
