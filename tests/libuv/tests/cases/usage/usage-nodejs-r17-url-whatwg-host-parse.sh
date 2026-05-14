#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-url-whatwg-host-parse
# @title: Node.js WHATWG URL parses a URL and exposes hostname, pathname, and protocol
# @description: Constructs new URL('https://example.test:8443/r17/path?q=1'), asserts hostname equals 'example.test', port equals '8443', pathname equals '/r17/path', protocol equals 'https:', and searchParams.get('q') equals '1', exercising the WHATWG URL parser shipped with Node.js.
# @timeout: 60
# @tags: usage, nodejs, url, whatwg, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const u = new URL('https://example.test:8443/r17/path?q=1');
assert.strictEqual(u.hostname, 'example.test');
assert.strictEqual(u.port, '8443');
assert.strictEqual(u.pathname, '/r17/path');
assert.strictEqual(u.protocol, 'https:');
assert.strictEqual(u.searchParams.get('q'), '1');
console.log('OK url.host=' + u.hostname);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK url.host=example.test'
