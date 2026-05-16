#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-fs-watch-detects-create-event
# @title: Node.js fs.watch fires a rename event when a file is created in the watched directory
# @description: Watches a tmpdir via fs.watch (which uses libuv's uv_fs_event), then creates a new file inside that directory and asserts a 'rename' event with the matching filename is received within a short timeout, exercising libuv's inotify-backed filesystem event surface.
# @timeout: 60
# @tags: usage, fs, watch, libuv, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<JS
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const dir = process.argv[2];
let resolved = false;

const watcher = fs.watch(dir, (event, filename) => {
  if (resolved) return;
  if (filename === 'newly-created.txt') {
    resolved = true;
    watcher.close();
    console.log('OK fs.watch event=' + event + ' file=' + filename);
  }
});

setTimeout(() => fs.writeFileSync(path.join(dir, 'newly-created.txt'), 'hi'), 50);

setTimeout(() => {
  if (!resolved) {
    watcher.close();
    process.exitCode = 1;
    console.error('fs.watch timed out');
  }
}, 3000);
JS

node "$tmpdir/s.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.watch'
