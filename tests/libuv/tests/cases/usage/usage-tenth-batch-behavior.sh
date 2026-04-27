#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-nodejs-fs-truncate-file)
    FILE_PATH="$tmpdir/data.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'truncate payload extra');
fs.truncateSync(path, 8);
console.log(fs.readFileSync(path, 'utf8'));
JS
    validator_assert_contains "$tmpdir/out" 'truncate'
    ;;
  usage-nodejs-fs-stat-isfile)
    FILE_PATH="$tmpdir/file.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'stat payload');
console.log(fs.statSync(path).isFile());
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-buffer-from-hex)
    node >"$tmpdir/out" <<'JS'
const buf = Buffer.from('48656c6c6f', 'hex');
console.log(buf.toString('utf8'));
JS
    validator_assert_contains "$tmpdir/out" 'Hello'
    ;;
  usage-nodejs-url-pathname-parse)
    node >"$tmpdir/out" <<'JS'
const u = new URL('https://example.invalid/foo/bar?x=1');
console.log(u.pathname);
console.log(u.searchParams.get('x'));
JS
    validator_assert_contains "$tmpdir/out" '/foo/bar'
    validator_assert_contains "$tmpdir/out" '1'
    ;;
  usage-nodejs-os-tmpdir-defined)
    node >"$tmpdir/out" <<'JS'
const os = require('os');
const t = os.tmpdir();
if (typeof t !== 'string' || t.length === 0) throw new Error('no tmpdir');
console.log('tmpdir-ok');
JS
    validator_assert_contains "$tmpdir/out" 'tmpdir-ok'
    ;;
  usage-nodejs-events-emit-listener)
    node >"$tmpdir/out" <<'JS'
const { EventEmitter } = require('events');
const e = new EventEmitter();
e.on('hello', (m) => console.log('got:' + m));
e.emit('hello', 'world');
JS
    validator_assert_contains "$tmpdir/out" 'got:world'
    ;;
  usage-nodejs-fs-write-stream-end)
    FILE_PATH="$tmpdir/out.bin" node >"$tmpdir/log" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
const ws = fs.createWriteStream(path);
ws.write('write-stream-payload');
ws.end(() => console.log('done'));
JS
    validator_assert_contains "$tmpdir/log" 'done'
    validator_assert_contains "$tmpdir/out.bin" 'write-stream-payload'
    ;;
  usage-nodejs-crypto-sha256-hex)
    node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
console.log(crypto.createHash('sha256').update('validator').digest('hex'));
JS
    validator_assert_contains "$tmpdir/out" 'f82af32160bc53112ca118abbf57fa6fed47eb90291a1d1d92f438ae2ed74ef6'
    ;;
  usage-nodejs-zlib-deflatesync-roundtrip)
    node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
const compressed = zlib.deflateSync(Buffer.from('deflate payload'));
const restored = zlib.inflateSync(compressed).toString('utf8');
console.log(restored);
JS
    validator_assert_contains "$tmpdir/out" 'deflate payload'
    ;;
  usage-nodejs-process-hrtime-bigint)
    node >"$tmpdir/out" <<'JS'
const a = process.hrtime.bigint();
const b = process.hrtime.bigint();
if (b < a) throw new Error('non-monotonic hrtime');
console.log('monotonic-ok');
JS
    validator_assert_contains "$tmpdir/out" 'monotonic-ok'
    ;;
  *)
    printf 'unknown libuv tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
