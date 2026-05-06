#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-zlib-deflateraw-roundtrip
# @title: Node.js zlib deflateRawSync inflateRawSync roundtrip
# @description: Compresses 32 KiB of pseudo-random bytes with zlib.deflateRawSync (no zlib header) and verifies inflateRawSync recovers the original payload byte-for-byte.
# @timeout: 30
# @tags: usage, zlib, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const assert = require('assert');
const zlib = require('zlib');
const crypto = require('crypto');

const original = crypto.randomBytes(32 * 1024);
const compressed = zlib.deflateRawSync(original);
assert.ok(compressed.length > 0, 'compressed length non-zero');
// raw deflate has no zlib header, so byte 0 should not be 0x78 in typical cases
const restored = zlib.inflateRawSync(compressed);
assert.strictEqual(restored.length, original.length);
assert.ok(original.equals(restored), 'roundtrip equality');
JS
