#!/usr/bin/env node
// Builds supabase/seed_catalog.sql from the Pokémon TCG API (pokemontcg.io).
//
//   node tools/import_catalog.mjs --sets base1,base2,jungle
//   node tools/import_catalog.mjs --sets base1 --out my_seed.sql
//
// EVERY set and card in the API (about 20,000 cards):
//
//   node tools/import_catalog.mjs --all --split supabase/seed
//       Writes numbered files (seed_001.sql, seed_002.sql, ...) of at most
//       ~1 MB each, so each one can be pasted into the SQL editor. Run them in
//       order (the first one also contains all the sets).
//
//   SUPABASE_URL=... SUPABASE_SECRET_KEY=... node tools/import_catalog.mjs --all --push
//       Uploads straight to your database, no pasting. The secret (service
//       role) key stays on your computer; never put it in the app.
//
//   Add --resume to skip sets that are already listed in a previous --push run
//   (progress is kept in tools/.import_progress.json).
//
// Then paste the generated file into the Supabase SQL editor and run it.
// Running it again later refreshes prices (rows are upserted by id).
//
// Needs Node 18+ (built-in fetch). No packages to install. An API key is
// optional but gives higher rate limits: set POKEMONTCG_API_KEY.
//
// Find set ids at https://api.pokemontcg.io/v2/sets (for example base1 is Base
// Set and jungle is Jungle).

import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const API = 'https://api.pokemontcg.io/v2';

// ---- the mappings the app depends on (exported for testing) ---------------

// Wording the app already uses for a set, if it differs from the API's.
export const SET_NAME_OVERRIDES = { base1: 'Base Set' };

const APP_TYPES = new Set([
  'colorless', 'grass', 'fire', 'water', 'lightning', 'fighting', 'psychic',
  'darkness', 'metal', 'dragon', 'fairy',
]);

// The app groups rarities into fixed tiers (kRarityOptions in the Dart code).
export function normalizeRarity(raw) {
  const r = (raw ?? '').trim().toLowerCase();
  if (r === 'common') return 'Common';
  if (r === 'uncommon') return 'Uncommon';
  if (r === 'rare' || r === 'rare holo') return 'Rare';
  if (r === 'double rare') return 'Double Rare';
  if (r === 'illustration rare') return 'Illustration Rare';
  if (r === 'special illustration rare') return 'Special Illustration Rare';
  if (r === 'hyper rare' || r === 'rare secret' || r === 'rare rainbow') return 'Hyper Rare';
  if (r.startsWith('promo')) return 'Promo';
  return 'Other/Additional Rarities';
}

export function mapSupertype(raw) {
  const s = (raw ?? '').toLowerCase();
  if (s.startsWith('trainer')) return 'trainer';
  if (s.startsWith('energy')) return 'energy';
  return 'pokemon';
}

export function mapType(card, supertype) {
  const first = (card.types?.[0] ?? '').toLowerCase();
  if (APP_TYPES.has(first)) return first;
  if (supertype === 'energy') {
    // Basic energy cards name their type: "Fire Energy".
    const word = card.name.split(' ')[0].toLowerCase();
    if (APP_TYPES.has(word)) return word;
  }
  return 'colorless';
}

export function mapSubtype(card, supertype) {
  const subtypes = card.subtypes ?? [];
  if (supertype === 'energy') return subtypes.includes('Basic') ? 'Basic' : 'Special';
  if (supertype === 'trainer') {
    for (const s of ['Item', 'Supporter', 'Stadium']) if (subtypes.includes(s)) return s;
    return subtypes.length ? 'Item' : null; // tools, TMs… are items in the rules
  }
  return subtypes[0] ?? null;
}

// Several printings can be priced (normal, holofoil, reverse…). Prefer the
// plain one, since that is the usual copy; fall back to whatever is listed.
const PRICE_ORDER = [
  'normal', 'unlimitedNormal', 'holofoil', 'unlimitedHolofoil',
  'reverseHolofoil', '1stEditionNormal', '1stEditionHolofoil',
];

export function pickPrice(card) {
  const prices = card.tcgplayer?.prices;
  if (!prices) return { usd: null, updated: null };
  const keys = [...PRICE_ORDER, ...Object.keys(prices)];
  for (const key of keys) {
    const market = prices[key]?.market;
    if (typeof market === 'number') {
      return { usd: market, updated: toIsoDate(card.tcgplayer.updatedAt) };
    }
  }
  return { usd: null, updated: null };
}

// "2025/10/03" -> "2025-10-03"; anything unparseable -> null.
export function toIsoDate(value) {
  if (!value) return null;
  const m = /^(\d{4})[/-](\d{2})[/-](\d{2})/.exec(value);
  return m ? `${m[1]}-${m[2]}-${m[3]}` : null;
}

// ---- SQL building ---------------------------------------------------------

const q = (v) => (v === null || v === undefined || v === '' ? 'null' : `'${String(v).replaceAll("'", "''")}'`);
const n = (v) => (typeof v === 'number' && Number.isFinite(v) ? String(v) : 'null');

export function setRow(set) {
  const name = SET_NAME_OVERRIDES[set.id] ?? set.name;
  return `(${q(set.id)}, ${q(name)}, ${q(set.series ?? '')}, ${n(set.printedTotal)}, ${n(set.total)}, ${q(toIsoDate(set.releaseDate))}, ${q(set.images?.logo)}, ${q(set.images?.symbol)})`;
}

export function cardRow(card) {
  const supertype = mapSupertype(card.supertype);
  const { usd, updated } = pickPrice(card);
  return `(${[
    q(card.id), q(card.set.id), q(card.number), q(card.name), q(supertype),
    q(mapSubtype(card, supertype)), q(mapType(card, supertype)),
    q(normalizeRarity(card.rarity)), q(card.rarity), q(card.images?.small),
    q(card.images?.large), n(usd), q(updated),
  ].join(', ')})`;
}

function insertStatements(table, columns, rows, conflictCols, batch = 200) {
  const updates = columns
    .filter((c) => !conflictCols.includes(c))
    .map((c) => `${c} = excluded.${c}`)
    .join(', ');
  const out = [];
  for (let i = 0; i < rows.length; i += batch) {
    out.push(
      `insert into public.${table} (${columns.join(', ')}) values\n` +
        rows.slice(i, i + batch).join(',\n') +
        `\non conflict (${conflictCols.join(', ')}) do update set ${updates};\n`,
    );
  }
  return out;
}

export function buildSql(sets, cards) {
  const setSql = insertStatements(
    'card_sets',
    ['id', 'name', 'series', 'printed_total', 'total', 'release_date', 'logo_url', 'symbol_url'],
    sets.map(setRow), ['id'],
  );
  const cardSql = insertStatements(
    'card_catalog',
    ['id', 'set_id', 'number', 'name', 'supertype', 'subtype', 'type', 'rarity',
      'rarity_raw', 'image_small', 'image_large', 'market_price_usd', 'price_updated_at'],
    cards.map(cardRow), ['id'],
  );
  return [
    '-- Generated by tools/import_catalog.mjs — safe to run again (upserts by id).',
    `-- ${sets.length} set(s), ${cards.length} card(s).`,
    ...setSql, ...cardSql,
  ].join('\n');
}

// ---- fetching -------------------------------------------------------------

async function getJson(url, tries = 5) {
  const headers = process.env.POKEMONTCG_API_KEY
    ? { 'X-Api-Key': process.env.POKEMONTCG_API_KEY } : {};
  for (let attempt = 1; ; attempt++) {
    try {
      const res = await fetch(url, { headers });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (err) {
      if (attempt >= tries) throw new Error(`${url} failed: ${err.message}`);
      const wait = 1500 * attempt;
      console.error(`  retrying in ${wait} ms (${err.message})`);
      await new Promise((r) => setTimeout(r, wait));
    }
  }
}

async function fetchSet(id) {
  return (await getJson(`${API}/sets/${encodeURIComponent(id)}`)).data;
}

async function fetchCards(setId) {
  const all = [];
  for (let page = 1; ; page++) {
    const body = await getJson(
      `${API}/cards?q=${encodeURIComponent(`set.id:${setId}`)}&page=${page}&pageSize=250`,
    );
    all.push(...body.data);
    if (all.length >= body.totalCount || body.data.length === 0) break;
  }
  return all;
}

async function fetchAllSets() {
  const all = [];
  for (let page = 1; ; page++) {
    const body = await getJson(`${API}/sets?page=${page}&pageSize=250&orderBy=releaseDate`);
    all.push(...body.data);
    if (all.length >= body.totalCount || body.data.length === 0) break;
  }
  return all;
}

// Splits the whole import into pieces of at most `maxBytes` of SQL. The sets
// go in the first piece; each later piece holds whole insert statements.
export function chunkSql(statements, maxBytes = 1_000_000) {
  const files = [];
  let current = [];
  let size = 0;
  for (const st of statements) {
    const len = Buffer.byteLength(st);
    if (size + len > maxBytes && current.length) {
      files.push(current);
      current = [];
      size = 0;
    }
    current.push(st);
    size += len;
  }
  if (current.length) files.push(current);
  return files;
}

async function pushRows(table, rows, onConflict = 'id', batch = 500) {
  const base = process.env.SUPABASE_URL?.replace(/\/$/, '');
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!base || !key) {
    console.error('--push needs SUPABASE_URL and SUPABASE_SECRET_KEY in the environment.');
    process.exit(1);
  }
  for (let i = 0; i < rows.length; i += batch) {
    const res = await fetch(`${base}/rest/v1/${table}?on_conflict=${onConflict}`, {
      method: 'POST',
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
        Prefer: 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify(rows.slice(i, i + batch)),
    });
    if (!res.ok) throw new Error(`${table} upload failed: HTTP ${res.status} ${await res.text()}`);
  }
}

export function setJson(set) {
  return {
    id: set.id, name: SET_NAME_OVERRIDES[set.id] ?? set.name, series: set.series ?? '',
    printed_total: set.printedTotal ?? null, total: set.total ?? null,
    release_date: toIsoDate(set.releaseDate), logo_url: set.images?.logo ?? null,
    symbol_url: set.images?.symbol ?? null,
  };
}

export function cardJson(card) {
  const supertype = mapSupertype(card.supertype);
  const { usd, updated } = pickPrice(card);
  return {
    id: card.id, set_id: card.set.id, number: card.number, name: card.name,
    supertype, subtype: mapSubtype(card, supertype), type: mapType(card, supertype),
    rarity: normalizeRarity(card.rarity), rarity_raw: card.rarity ?? null,
    image_small: card.images?.small ?? null, image_large: card.images?.large ?? null,
    market_price_usd: usd, price_updated_at: updated,
  };
}

async function main() {
  const args = process.argv.slice(2);
  const get = (flag) => {
    const i = args.indexOf(flag);
    return i === -1 ? null : args[i + 1];
  };
  const all = args.includes('--all');
  const push = args.includes('--push');
  const resume = args.includes('--resume');
  const splitPrefix = get('--split');
  let ids = (get('--sets') ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  const out = get('--out') ?? 'supabase/seed_catalog.sql';
  if (ids.length === 0 && !all) {
    console.error('Usage: node tools/import_catalog.mjs (--sets base1,jungle | --all) [--out file.sql | --split prefix | --push] [--resume]');
    process.exit(1);
  }

  let sets = [];
  if (all) {
    console.error('Listing every set…');
    sets = await fetchAllSets();
    ids = sets.map((s) => s.id);
    console.error(`  ${ids.length} sets`);
  }

  const progressFile = 'tools/.import_progress.json';
  const done = new Set(resume && existsSync(progressFile) ? JSON.parse(readFileSync(progressFile, 'utf8')) : []);

  const cards = [];
  let total = 0;
  for (const id of ids) {
    if (push && done.has(id)) { console.error(`Skipping ${id} (already pushed)`); continue; }
    console.error(`Fetching ${id}…`);
    const set = all ? sets.find((s) => s.id === id) : await fetchSet(id);
    if (!all) sets.push(set);
    const setCards = await fetchCards(id);
    console.error(`  ${setCards.length} cards`);
    total += setCards.length;
    if (push) {
      // Sets first so the cards' foreign key is satisfied; then this set's cards.
      await pushRows('card_sets', [setJson(set)]);
      await pushRows('card_catalog', setCards.map(cardJson));
      done.add(id);
      writeFileSync(progressFile, JSON.stringify([...done]));
    } else {
      cards.push(...setCards);
    }
  }

  if (push) {
    console.error(`Uploaded ${total} card(s).`);
    return;
  }
  if (splitPrefix) {
    const statements = [
      ...insertStatements(
        'card_sets',
        ['id', 'name', 'series', 'printed_total', 'total', 'release_date', 'logo_url', 'symbol_url'],
        sets.map(setRow), ['id'],
      ),
      ...insertStatements(
        'card_catalog',
        ['id', 'set_id', 'number', 'name', 'supertype', 'subtype', 'type', 'rarity',
          'rarity_raw', 'image_small', 'image_large', 'market_price_usd', 'price_updated_at'],
        cards.map(cardRow), ['id'],
      ),
    ];
    const files = chunkSql(statements);
    files.forEach((chunk, i) => {
      const name = `${splitPrefix}_${String(i + 1).padStart(3, '0')}.sql`;
      writeFileSync(name, `-- Part ${i + 1} of ${files.length}. Run the parts in order.\n` + chunk.join('\n'));
      console.error(`Wrote ${name}`);
    });
    console.error(`${sets.length} set(s), ${cards.length} card(s) in ${files.length} file(s).`);
    return;
  }
  writeFileSync(out, buildSql(sets, cards));
  console.error(`Wrote ${out}`);
}

import { fileURLToPath } from 'node:url';
if (process.argv[1] === fileURLToPath(import.meta.url)) await main();
