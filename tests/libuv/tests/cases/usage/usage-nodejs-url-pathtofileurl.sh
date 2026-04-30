#!/usr/bin/env bash
# @testcase: usage-nodejs-url-pathtofileurl
# @title: Node.js url.pathToFileURL
# @description: Converts an absolute filesystem path to a file:// URL with url.pathToFileURL and verifies the protocol and pathname round-trip back through fileURLToPath.
# @timeout: 120
# @tags: usage, nodejs, url
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-url-pathtofileurl"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const { pathToFileURL, fileURLToPath } = require('url');
const u = pathToFileURL('/tmp/example file.txt');
if (u.protocol !== 'file:') throw new Error('protocol=' + u.protocol);
if (u.pathname !== '/tmp/example%20file.txt') throw new Error('pathname=' + u.pathname);
const restored = fileURLToPath(u);
if (restored !== '/tmp/example file.txt') throw new Error('restored=' + restored);
console.log('pathtofileurl ok href=' + u.href);
console.log('pathtofileurl ok restored=' + restored);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'pathtofileurl ok href=file:///tmp/example%20file.txt'
validator_assert_contains "$tmpdir/out" 'pathtofileurl ok restored=/tmp/example file.txt'
