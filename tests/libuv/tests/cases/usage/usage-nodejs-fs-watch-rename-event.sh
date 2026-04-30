#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-watch-rename-event
# @title: Node.js fs.watch directory rename event
# @description: Watches a temporary directory and verifies fs.watch surfaces a rename event when a new file appears.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

WATCH_DIR="$tmpdir/watchdir" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const dir = process.env.WATCH_DIR;
fs.mkdirSync(dir, { recursive: true });

let observed = false;
const timer = setTimeout(() => {
  if (!observed) {
    watcher.close();
    console.error('timed out waiting for fs.watch rename');
    process.exit(1);
  }
}, 3000);

const watcher = fs.watch(dir, (eventType, filename) => {
  if (eventType === 'rename' && filename === 'created.txt' && !observed) {
    observed = true;
    clearTimeout(timer);
    watcher.close();
    assert.strictEqual(fs.readFileSync(path.join(dir, 'created.txt'), 'utf8'), 'hello');
    console.log('OK rename');
  }
});

setTimeout(() => {
  fs.writeFileSync(path.join(dir, 'created.txt'), 'hello');
}, 75);
JS

validator_assert_contains "$tmpdir/out" 'OK rename'
