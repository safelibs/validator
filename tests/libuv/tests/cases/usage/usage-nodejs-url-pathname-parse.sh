#!/usr/bin/env bash
# @testcase: usage-nodejs-url-pathname-parse
# @title: nodejs URL pathname parse
# @description: Parses a URL through the global URL constructor and verifies pathname plus query parameter access.
# @timeout: 180
# @tags: usage, nodejs, url
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-url-pathname-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const u = new URL('https://example.invalid/foo/bar?x=1');
console.log(u.pathname);
console.log(u.searchParams.get('x'));
JS
validator_assert_contains "$tmpdir/out" '/foo/bar'
validator_assert_contains "$tmpdir/out" '1'
