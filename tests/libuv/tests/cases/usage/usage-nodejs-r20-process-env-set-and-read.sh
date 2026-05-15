#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-process-env-set-and-read
# @title: Node.js process.env assignment is visible to the same Node.js process
# @description: Assigns process.env.R20_VALIDATOR_VAR = 'r20-value', reads process.env.R20_VALIDATOR_VAR back, and asserts the returned string equals 'r20-value' exactly, deletes the key and asserts subsequent read returns undefined, confirming Node's libuv-built environment proxy reflects in-process mutations.
# @timeout: 60
# @tags: usage, nodejs, process, env, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
process.env.R20_VALIDATOR_VAR = 'r20-value';
assert.strictEqual(process.env.R20_VALIDATOR_VAR, 'r20-value');
delete process.env.R20_VALIDATOR_VAR;
assert.strictEqual(process.env.R20_VALIDATOR_VAR, undefined);
console.log('OK env');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK env'
