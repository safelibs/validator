#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-text-decoder-utf16le-bom
# @title: Node.js TextDecoder utf-16le strips BOM
# @description: Encodes ASCII text into a UTF-16LE byte sequence with a leading 0xFF 0xFE BOM and verifies the standard TextDecoder('utf-16le') decodes it without surfacing the BOM in the resulting string.
# @timeout: 30
# @tags: usage, util, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const assert = require('assert');

const text = 'hello world';
const utf16 = Buffer.alloc(2 + text.length * 2);
utf16[0] = 0xff;
utf16[1] = 0xfe;
for (let i = 0; i < text.length; i++) {
  utf16.writeUInt16LE(text.charCodeAt(i), 2 + i * 2);
}

const dec = new TextDecoder('utf-16le');
const out = dec.decode(utf16);
// Default ignoreBOM = false → BOM consumed and not present in output.
assert.strictEqual(out, text);

const decKeep = new TextDecoder('utf-16le', { ignoreBOM: true });
const outKeep = decKeep.decode(utf16);
assert.strictEqual(outKeep.length, text.length + 1);
assert.strictEqual(outKeep.charCodeAt(0), 0xfeff);
JS
