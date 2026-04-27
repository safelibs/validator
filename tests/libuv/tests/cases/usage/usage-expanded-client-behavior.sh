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
  usage-nodejs-fs-rename-file)
    TMPDIR="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs/promises');
const path = require('path');
const root = process.env.TMPDIR;
(async () => {
  const source = path.join(root, 'before.txt');
  const dest = path.join(root, 'after.txt');
  await fs.writeFile(source, 'rename payload\n');
  await fs.rename(source, dest);
  console.log((await fs.readFile(dest, 'utf8')).trim());
})();
JS
    validator_assert_contains "$tmpdir/out" 'rename payload'
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
  usage-nodejs-stream-finished-pass-through)
    node >"$tmpdir/out" <<'JS'
const { PassThrough } = require('stream');
const { finished } = require('stream/promises');
(async () => {
  const stream = new PassThrough();
  let output = '';
  stream.on('data', (chunk) => { output += chunk.toString('utf8'); });
  stream.end('finished payload');
  await finished(stream);
  console.log(output);
})();
JS
    validator_assert_contains "$tmpdir/out" 'finished payload'
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
  usage-nodejs-net-isip-loopback)
    node >"$tmpdir/out" <<'JS'
const net = require('net');
console.log(net.isIP('127.0.0.1'));
JS
    validator_assert_contains "$tmpdir/out" '4'
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
  usage-nodejs-timers-promises-immediate)
    node >"$tmpdir/out" <<'JS'
const timersPromises = require('timers/promises');
(async () => {
  const value = await timersPromises.setImmediate('immediate done');
  console.log(value);
})();
JS
    validator_assert_contains "$tmpdir/out" 'immediate done'
    ;;
  *)
    printf 'unknown libuv expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
