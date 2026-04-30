#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-stat-bigint
# @title: Node.js fs.stat with bigint=true returns BigInt sizes
# @description: Calls fs.promises.stat with the bigint option and asserts size, ino, and mtimeNs are BigInt values matching the byte length.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TARGET_FILE="$tmpdir/bigint.bin" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');

(async () => {
  const file = process.env.TARGET_FILE;
  const payload = Buffer.alloc(2048, 0x37);
  await fsp.writeFile(file, payload);

  const stat = await fsp.stat(file, { bigint: true });
  assert.strictEqual(typeof stat.size, 'bigint');
  assert.strictEqual(typeof stat.ino, 'bigint');
  assert.strictEqual(typeof stat.mtimeNs, 'bigint');
  assert.strictEqual(stat.size, BigInt(payload.length));
  assert.ok(stat.ino > 0n, 'ino must be positive bigint');
  assert.ok(stat.mtimeNs > 0n, 'mtimeNs must be positive bigint');
  assert.strictEqual(stat.isFile(), true);

  console.log('OK bigint size', stat.size.toString());
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK bigint size 2048'
