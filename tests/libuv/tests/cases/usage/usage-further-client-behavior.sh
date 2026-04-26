#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-nodejs-fs-mkdtemp)
    TMPROOT="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = require('path');
const target = fs.mkdtempSync(path.join(process.env.TMPROOT, 'uv-'));
console.log(path.basename(target).startsWith('uv-'));
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-fs-chmod)
    FILE_PATH="$tmpdir/file.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'chmod payload\n');
fs.chmod(path, 0o640, (error) => {
  if (error) throw error;
  const mode = fs.statSync(path).mode & 0o777;
  console.log(mode.toString(8));
});
JS
    validator_assert_contains "$tmpdir/out" '640'
    ;;
  usage-nodejs-fs-symlink-readlink)
    TMPDIR_PATH="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = require('path');
const tmpdir = process.env.TMPDIR_PATH;
const target = path.join(tmpdir, 'target.txt');
const link = path.join(tmpdir, 'link.txt');
fs.writeFileSync(target, 'symlink payload\n');
fs.symlink(target, link, (error) => {
  if (error) throw error;
  fs.readlink(link, (readError, value) => {
    if (readError) throw readError;
    console.log(path.basename(value));
  });
});
JS
    validator_assert_contains "$tmpdir/out" 'target.txt'
    ;;
  usage-nodejs-child-process-execsync)
    node >"$tmpdir/out" <<'JS'
const { execSync } = require('child_process');
const value = execSync('printf execsync-ok').toString('utf8');
console.log(value);
JS
    validator_assert_contains "$tmpdir/out" 'execsync-ok'
    ;;
  usage-nodejs-net-end-event)
    node >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer((socket) => {
  socket.end('done');
});
server.listen(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = net.createConnection({ port, host: '127.0.0.1' });
  let data = '';
  client.on('data', (chunk) => { data += chunk.toString('utf8'); });
  client.on('end', () => {
    console.log(data);
    server.close();
  });
});
JS
    validator_assert_contains "$tmpdir/out" 'done'
    ;;
  usage-nodejs-dgram-message-size)
    node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const server = dgram.createSocket('udp4');
server.on('message', (message) => {
  console.log(message.length);
  server.close();
});
server.bind(0, '127.0.0.1', () => {
  const { port } = server.address();
  const client = dgram.createSocket('udp4');
  client.send(Buffer.from('payload'), port, '127.0.0.1', () => client.close());
});
JS
    validator_assert_contains "$tmpdir/out" '7'
    ;;
  usage-nodejs-stream-finished)
    node >"$tmpdir/out" <<'JS'
const { PassThrough, finished } = require('stream');
const stream = new PassThrough();
let data = '';
stream.on('data', (chunk) => { data += chunk.toString('utf8'); });
finished(stream, (error) => {
  if (error) throw error;
  console.log(data);
});
stream.end('stream-finished');
JS
    validator_assert_contains "$tmpdir/out" 'stream-finished'
    ;;
  usage-nodejs-crypto-randomfill)
    node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
const buffer = Buffer.alloc(8);
crypto.randomFill(buffer, (error, filled) => {
  if (error) throw error;
  console.log(filled.length);
});
JS
    validator_assert_contains "$tmpdir/out" '8'
    ;;
  usage-nodejs-zlib-brotli-compress)
    node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
zlib.brotliCompress(Buffer.from('brotli payload'), (error, output) => {
  if (error) throw error;
  zlib.brotliDecompress(output, (decompressError, restored) => {
    if (decompressError) throw decompressError;
    console.log(restored.toString('utf8'));
  });
});
JS
    validator_assert_contains "$tmpdir/out" 'brotli payload'
    ;;
  usage-nodejs-timers-timeout-refresh)
    node >"$tmpdir/out" <<'JS'
let count = 0;
const timeout = setTimeout(() => {
  count += 1;
  console.log(`count=${count}`);
}, 20);
setTimeout(() => timeout.refresh(), 5);
JS
    validator_assert_contains "$tmpdir/out" 'count=1'
    ;;
  *)
    printf 'unknown libuv further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
