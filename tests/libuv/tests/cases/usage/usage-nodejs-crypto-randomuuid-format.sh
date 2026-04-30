#!/usr/bin/env bash
# @testcase: usage-nodejs-crypto-randomuuid-format
# @title: Node.js crypto.randomUUID format check
# @description: Generates several crypto.randomUUID values and validates they match RFC 4122 v4 format with version 4 and variant bits set correctly, and are unique across the batch.
# @timeout: 180
# @tags: usage, nodejs, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const crypto = require('crypto');

const re = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const ids = new Set();
const N = 32;
for (let i = 0; i < N; i++) {
  const id = crypto.randomUUID();
  assert.strictEqual(typeof id, 'string');
  assert.strictEqual(id.length, 36, `wrong length: ${id}`);
  assert.ok(re.test(id), `bad uuid: ${id}`);
  ids.add(id);
}
assert.strictEqual(ids.size, N, 'duplicate UUIDs generated');
console.log('OK randomuuid', N, ids.size);
JS

validator_assert_contains "$tmpdir/out" 'OK randomuuid 32 32'
