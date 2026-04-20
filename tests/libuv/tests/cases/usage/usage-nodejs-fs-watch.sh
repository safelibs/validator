#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$tmpdir/watched.txt" <<'JS' | tee "$tmpdir/out"
const fs = require('fs');
const path = process.argv[2];

fs.writeFileSync(path, 'initial');

let observed = false;
const timer = setTimeout(() => {
  if (!observed) {
    watcher.close();
    console.error('timed out waiting for fs.watch change');
    process.exit(1);
  }
}, 2000);

const watcher = fs.watch(path, (eventType) => {
  if (eventType !== 'change' || observed) {
    return;
  }
  observed = true;
  clearTimeout(timer);
  watcher.close();
  console.log('change');
});

setTimeout(() => {
  fs.appendFileSync(path, '-updated');
}, 50);
JS

validator_assert_contains "$tmpdir/out" 'change'
