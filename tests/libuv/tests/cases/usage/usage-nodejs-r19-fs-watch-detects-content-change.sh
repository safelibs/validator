#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-fs-watch-detects-content-change
# @title: Node.js fs.watch fires a change event after appendFile mutates a watched file
# @description: Writes an initial file, opens an fs.watch handle on its parent directory, schedules an fs.promises.appendFile of a new chunk after 30ms, and asserts the watcher receives at least one 'change' (or 'rename') event whose filename equals the file's basename before timeout, exercising libuv's inotify/kqueue-backed fs.watch on a real mutation.
# @timeout: 60
# @tags: usage, nodejs, fs, watch, inotify, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

(async () => {
  const dir = '$tmpdir';
  const file = path.join(dir, 'watched.txt');
  await fsp.writeFile(file, 'initial\n');

  let saw = false;
  const watcher = fs.watch(dir, (eventType, filename) => {
    if (filename === 'watched.txt') saw = true;
  });

  setTimeout(() => fsp.appendFile(file, 'more\n'), 30);

  const deadline = Date.now() + 4000;
  while (!saw && Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 25));
  }
  watcher.close();
  assert.ok(saw, 'no watch event observed');
  console.log('OK watch.event');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK watch.event'
