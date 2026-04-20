#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node <<'JS' | tee "$tmpdir/out"
const crypto = require('crypto');

let completed = false;
const timer = setTimeout(() => {
  if (!completed) {
    console.error('timed out waiting for pbkdf2 callback');
    process.exit(1);
  }
}, 2000);

crypto.pbkdf2('password', 'salt', 1000, 32, 'sha256', (error, key) => {
  if (error) {
    throw error;
  }
  if (!Buffer.isBuffer(key) || key.length !== 32) {
    throw new Error(`unexpected key length: ${key.length}`);
  }
  completed = true;
  clearTimeout(timer);
  console.log(`pbkdf2:${key.length}`);
});
JS

validator_assert_contains "$tmpdir/out" 'pbkdf2:32'
