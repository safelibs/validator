#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-process-versions-has-node-and-uv
# @title: Node.js process.versions exposes both node and uv version strings
# @description: Reads process.versions, asserts both the node and uv keys are present, that each value is a non-empty string, and that each begins with a digit followed by a dot — confirming Node.js surfaces its libuv version through the standard API.
# @timeout: 60
# @tags: usage, nodejs, process, versions
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const v = process.versions;
assert.ok(typeof v.node === 'string' && v.node.length > 0, 'node');
assert.ok(typeof v.uv === 'string' && v.uv.length > 0, 'uv');
assert.ok(/^\d+\./.test(v.node), v.node);
assert.ok(/^\d+\./.test(v.uv), v.uv);
console.log('OK versions node=' + v.node + ' uv=' + v.uv);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK versions'
