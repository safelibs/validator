#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-process-versions-has-v8-and-node
# @title: Node.js process.versions exposes string values for "node" and "v8"
# @description: Reads process.versions and asserts both the "node" and "v8" entries exist as non-empty strings matching the dotted version pattern '^\d+\.\d+', confirming the runtime metadata is intact.
# @timeout: 60
# @tags: usage, nodejs, process, versions, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const v = process.versions;
assert.strictEqual(typeof v.node, 'string');
assert.strictEqual(typeof v.v8, 'string');
assert.ok(/^\d+\.\d+/.test(v.node), 'node version pattern: ' + v.node);
assert.ok(/^\d+\.\d+/.test(v.v8), 'v8 version pattern: ' + v.v8);
console.log('OK versions node=' + v.node + ' v8=' + v.v8);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK versions node='
