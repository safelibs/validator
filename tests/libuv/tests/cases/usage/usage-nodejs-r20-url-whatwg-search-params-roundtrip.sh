#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-url-whatwg-search-params-roundtrip
# @title: Node.js WHATWG URL searchParams round-trip preserves a value with spaces
# @description: Constructs new URL('https://example.com/x?q=hello%20world&n=5'), reads searchParams.get('q') and asserts it equals 'hello world' (URL-decoded), reads searchParams.get('n') and asserts it equals '5', then sets searchParams.set('q', 'foo bar') and asserts url.search now contains 'q=foo+bar' (form-style encoding), confirming Node's URL+URLSearchParams interaction follows the WHATWG spec.
# @timeout: 60
# @tags: usage, nodejs, url, search-params, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const u = new URL('https://example.com/x?q=hello%20world&n=5');
assert.strictEqual(u.searchParams.get('q'), 'hello world');
assert.strictEqual(u.searchParams.get('n'), '5');
u.searchParams.set('q', 'foo bar');
assert.ok(u.search.includes('q=foo+bar'), 'search=' + u.search);
console.log('OK searchParams ' + u.search);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK searchParams'
