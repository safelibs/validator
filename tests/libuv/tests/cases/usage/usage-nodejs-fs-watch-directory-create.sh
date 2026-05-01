#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-watch-directory-create
# @title: Node.js fs.watch directory create event
# @description: Watches a directory with fs.watch and verifies a rename event fires when a new file is created inside it.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$tmpdir" <<'JS' >"$tmpdir/out"
const fs = require('fs');
const path = require('path');
const dir = process.argv[2];

let observed = false;
const timer = setTimeout(() => {
  if (!observed) {
    watcher.close();
    console.error('timed out waiting for fs.watch dir rename event');
    process.exit(1);
  }
}, 3000);

const watcher = fs.watch(dir, (eventType, filename) => {
  if (eventType !== 'rename' || filename !== 'created.txt' || observed) return;
  observed = true;
  clearTimeout(timer);
  watcher.close();
  console.log('rename created.txt');
});

setTimeout(() => {
  fs.writeFileSync(path.join(dir, 'created.txt'), 'payload');
}, 50);
JS

validator_assert_contains "$tmpdir/out" 'rename created.txt'
