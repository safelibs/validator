#!/usr/bin/env bash
# @testcase: usage-nodejs-path-relative-between-abs
# @title: Node.js path.relative between absolute paths
# @description: Computes relative paths between two absolute filesystem paths with path.relative and verifies forward and backward traversal segments.
# @timeout: 120
# @tags: usage, nodejs, path
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-path-relative-between-abs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const path = require('path');
const forward = path.relative('/var/lib/foo', '/var/lib/foo/bar/baz');
if (forward !== 'bar/baz') throw new Error('forward=' + forward);
const backward = path.relative('/var/lib/foo/bar/baz', '/var/lib/foo');
if (backward !== '../..') throw new Error('backward=' + backward);
const sibling = path.relative('/var/lib/foo', '/var/lib/qux');
if (sibling !== '../qux') throw new Error('sibling=' + sibling);
const same = path.relative('/etc', '/etc');
if (same !== '') throw new Error('same=' + JSON.stringify(same));
console.log('path-relative ok forward=' + forward);
console.log('path-relative ok backward=' + backward);
console.log('path-relative ok sibling=' + sibling);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'path-relative ok forward=bar/baz'
validator_assert_contains "$tmpdir/out" 'path-relative ok backward=../..'
validator_assert_contains "$tmpdir/out" 'path-relative ok sibling=../qux'
