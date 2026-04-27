#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-nodejs-fs-promises-readfile)
    FILE_PATH="$tmpdir/input.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'promises payload\n');
(async () => {
  const data = await fs.promises.readFile(path, 'utf8');
  console.log(data.trim());
})();
JS
    validator_assert_contains "$tmpdir/out" 'promises payload'
    ;;
  usage-nodejs-fs-realpath-file)
    FILE_PATH="$tmpdir/input.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.FILE_PATH;
fs.writeFileSync(path, 'realpath payload\n');
fs.realpath(path, (error, resolved) => {
  if (error) throw error;
  console.log(resolved.endsWith('input.txt'));
});
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-fs-readdir-dirents)
    DIR_PATH="$tmpdir/list" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const path = process.env.DIR_PATH;
fs.mkdirSync(path, { recursive: true });
fs.writeFileSync(`${path}/alpha.txt`, 'alpha\n');
fs.writeFileSync(`${path}/beta.txt`, 'beta\n');
fs.readdir(path, { withFileTypes: true }, (error, entries) => {
  if (error) throw error;
  console.log(entries.map((entry) => entry.name).sort().join(','));
});
JS
    validator_assert_contains "$tmpdir/out" 'alpha.txt,beta.txt'
    ;;
  usage-nodejs-child-process-spawnsync-bash)
    node >"$tmpdir/out" <<'JS'
const { spawnSync } = require('child_process');
const result = spawnSync('bash', ['-lc', 'printf spawn-sync-ok']);
if (result.status !== 0) throw new Error('spawnSync failed');
console.log(result.stdout.toString('utf8'));
JS
    validator_assert_contains "$tmpdir/out" 'spawn-sync-ok'
    ;;
  usage-nodejs-stream-pipeline-pass-through)
    node >"$tmpdir/out" <<'JS'
const { PassThrough, pipeline } = require('stream');
const source = new PassThrough();
const middle = new PassThrough();
const sink = new PassThrough();
let output = '';
sink.on('data', (chunk) => { output += chunk.toString('utf8'); });
pipeline(source, middle, sink, (error) => {
  if (error) throw error;
  console.log(output);
});
source.end('pipeline payload');
JS
    validator_assert_contains "$tmpdir/out" 'pipeline payload'
    ;;
  usage-nodejs-zlib-gzip-roundtrip)
    node >"$tmpdir/out" <<'JS'
const zlib = require('zlib');
zlib.gzip(Buffer.from('gzip payload'), (error, compressed) => {
  if (error) throw error;
  zlib.gunzip(compressed, (restoreError, restored) => {
    if (restoreError) throw restoreError;
    console.log(restored.toString('utf8'));
  });
});
JS
    validator_assert_contains "$tmpdir/out" 'gzip payload'
    ;;
  usage-nodejs-crypto-randombytes)
    node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
const value = crypto.randomBytes(12);
console.log(value.length);
JS
    validator_assert_contains "$tmpdir/out" '12'
    ;;
  usage-nodejs-net-server-address-loopback)
    node >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer();
server.listen(0, '127.0.0.1', () => {
  const address = server.address();
  console.log(address.address, address.family);
  server.close();
});
JS
    validator_assert_contains "$tmpdir/out" '127.0.0.1'
    ;;
  usage-nodejs-dgram-close-event)
    node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const socket = dgram.createSocket('udp4');
socket.on('close', () => {
  console.log('closed');
});
socket.bind(0, '127.0.0.1', () => socket.close());
JS
    validator_assert_contains "$tmpdir/out" 'closed'
    ;;
  usage-nodejs-timers-setinterval-twice)
    node >"$tmpdir/out" <<'JS'
let count = 0;
const handle = setInterval(() => {
  count += 1;
  if (count === 2) {
    clearInterval(handle);
    console.log(`count=${count}`);
  }
}, 5);
JS
    validator_assert_contains "$tmpdir/out" 'count=2'
    ;;
  *)
    printf 'unknown libuv expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
