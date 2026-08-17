#!/usr/bin/env node
// Ledger for upwork-search-jobs. Dedupes by job id.
//
//   node store.mjs seen [--file PATH]            -> JSON array of seen ids
//   node store.mjs append [--file PATH] < a.json -> append new records, print summary
//   node store.mjs stats [--file PATH]           -> counts + date range
//
// Default ledger: ~/Projects/upwork/jobs/upwork-jobs.json

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { homedir } from 'node:os';

const DEFAULT_FILE = resolve(homedir(), 'Projects/upwork/jobs/upwork-jobs.json');

const argv = process.argv.slice(2);
const cmd = argv[0];
const fileFlag = argv.indexOf('--file');
const file = fileFlag !== -1 ? resolve(argv[fileFlag + 1]) : DEFAULT_FILE;

function load() {
  if (!existsSync(file)) return [];
  const raw = readFileSync(file, 'utf8').trim();
  if (!raw) return [];
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed)) throw new Error(`${file} is not a JSON array`);
  return parsed;
}

function save(records) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, `${JSON.stringify(records, null, 2)}\n`);
}

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function fail(msg) {
  console.error(msg);
  process.exit(1);
}

const existing = load();

if (cmd === 'seen') {
  console.log(JSON.stringify(existing.map((r) => String(r.id))));
} else if (cmd === 'append') {
  const input = readStdin().trim();
  if (!input) fail('append: no JSON on stdin');
  let incoming;
  try {
    incoming = JSON.parse(input);
  } catch (e) {
    fail(`append: stdin is not valid JSON — ${e.message}`);
  }
  if (!Array.isArray(incoming)) incoming = [incoming];

  const seen = new Set(existing.map((r) => String(r.id)));
  const today = new Date().toISOString().slice(0, 10);
  const added = [];
  const skipped = [];

  for (const rec of incoming) {
    if (!rec || rec.id === undefined || rec.id === null) fail('append: a record has no id');
    const id = String(rec.id);
    if (seen.has(id)) {
      skipped.push(id);
      continue;
    }
    seen.add(id);
    added.push({ ...rec, id, found_at: rec.found_at ?? today });
  }

  if (added.length) save([...existing, ...added]);
  console.log(
    JSON.stringify({
      file,
      added: added.length,
      skipped_duplicates: skipped.length,
      total: existing.length + added.length,
    }),
  );
} else if (cmd === 'stats') {
  const dates = existing.map((r) => r.found_at).filter(Boolean).sort();
  console.log(
    JSON.stringify({
      file,
      total: existing.length,
      first_found: dates[0] ?? null,
      last_found: dates.at(-1) ?? null,
    }),
  );
} else {
  fail('usage: store.mjs seen|append|stats [--file PATH]');
}
