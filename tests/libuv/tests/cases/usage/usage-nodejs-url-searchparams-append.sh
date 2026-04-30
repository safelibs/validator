#!/usr/bin/env bash
# @testcase: usage-nodejs-url-searchparams-append
# @title: Node.js URLSearchParams append and toString
# @description: Builds a URLSearchParams instance via append, verifies repeated keys preserve order, getAll returns all values, and toString produces the expected URL-encoded query string.
# @timeout: 180
# @tags: usage, nodejs, url
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');

const params = new URLSearchParams();
params.append('a', '1');
params.append('b', 'two words');
params.append('a', '2');
params.append('c', 'a&b=c');

assert.deepStrictEqual(params.getAll('a'), ['1', '2']);
assert.strictEqual(params.get('b'), 'two words');
assert.strictEqual(params.get('c'), 'a&b=c');

const expected = 'a=1&b=two+words&a=2&c=a%26b%3Dc';
assert.strictEqual(params.toString(), expected);

const url = new URL('https://example.test/path');
url.search = params.toString();
assert.strictEqual(url.searchParams.getAll('a').join(','), '1,2');
assert.strictEqual(url.searchParams.get('c'), 'a&b=c');

console.log('OK searchparams', params.toString());
JS

validator_assert_contains "$tmpdir/out" 'OK searchparams a=1&b=two+words&a=2&c=a%26b%3Dc'
