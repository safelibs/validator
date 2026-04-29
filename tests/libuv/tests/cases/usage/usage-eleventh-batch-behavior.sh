#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-nodejs-fs-promises-mkdtemp-batch11)
    TMP_PARENT="$tmpdir" node >"$tmpdir/out" <<'JS'
const fs = require('fs/promises');
(async () => {
  const dir = await fs.mkdtemp(process.env.TMP_PARENT + '/node-');
  console.log(dir.includes('/node-'));
})().catch(err => { console.error(err); process.exit(1); });
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-fs-realpath-native-batch11)
    FILE_PATH="$tmpdir/real.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
fs.writeFileSync(process.env.FILE_PATH, 'realpath');
console.log(fs.realpathSync.native(process.env.FILE_PATH).endsWith('real.txt'));
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-timers-promises-timeout-batch11)
    node >"$tmpdir/out" <<'JS'
const timers = require('timers/promises');
(async () => {
  const value = await timers.setTimeout(10, 'timer-ok');
  console.log(value);
})().catch(err => { console.error(err); process.exit(1); });
JS
    validator_assert_contains "$tmpdir/out" 'timer-ok'
    ;;
  usage-nodejs-net-server-address-batch11)
    node >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer(socket => socket.end('ok'));
server.listen(0, '127.0.0.1', () => {
  const address = server.address();
  console.log(address.address + ':' + (address.port > 0));
  server.close();
});
JS
    validator_assert_contains "$tmpdir/out" '127.0.0.1:true'
    ;;
  usage-nodejs-dgram-buffer-message-batch11)
    node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const server = dgram.createSocket('udp4');
server.on('message', msg => { console.log(msg.toString()); server.close(); });
server.bind(0, '127.0.0.1', () => {
  const client = dgram.createSocket('udp4');
  const port = server.address().port;
  client.send(Buffer.from('udp-buffer-ok'), port, '127.0.0.1', () => client.close());
});
JS
    validator_assert_contains "$tmpdir/out" 'udp-buffer-ok'
    ;;
  usage-nodejs-worker-thread-message-batch11)
    node >"$tmpdir/out" <<'JS'
const { Worker } = require('worker_threads');
const worker = new Worker("const { parentPort } = require('worker_threads'); parentPort.postMessage('worker-ok');", { eval: true });
worker.on('message', msg => console.log(msg));
worker.on('error', err => { throw err; });
JS
    validator_assert_contains "$tmpdir/out" 'worker-ok'
    ;;
  usage-nodejs-readline-async-iterator-batch11)
    node >"$tmpdir/out" <<'JS'
const readline = require('readline');
const { Readable } = require('stream');
(async () => {
  const rl = readline.createInterface({ input: Readable.from(['alpha\n', 'beta\n']) });
  const rows = [];
  for await (const line of rl) rows.push(line);
  console.log(rows.join(','));
})().catch(err => { console.error(err); process.exit(1); });
JS
    validator_assert_contains "$tmpdir/out" 'alpha,beta'
    ;;
  usage-nodejs-stream-finished-promise-batch11)
    OUT_PATH="$tmpdir/stream.txt" node >"$tmpdir/out" <<'JS'
const fs = require('fs');
const { finished } = require('stream/promises');
(async () => {
  const ws = fs.createWriteStream(process.env.OUT_PATH);
  ws.end('finished payload');
  await finished(ws);
  console.log(fs.readFileSync(process.env.OUT_PATH, 'utf8'));
})().catch(err => { console.error(err); process.exit(1); });
JS
    validator_assert_contains "$tmpdir/out" 'finished payload'
    ;;
  usage-nodejs-dns-promises-lookup-batch11)
    node >"$tmpdir/out" <<'JS'
const dns = require('dns').promises;
(async () => {
  const result = await dns.lookup('localhost');
  console.log(result.address.length > 0);
})().catch(err => { console.error(err); process.exit(1); });
JS
    validator_assert_contains "$tmpdir/out" 'true'
    ;;
  usage-nodejs-crypto-randombytes-async-batch11)
    node >"$tmpdir/out" <<'JS'
const crypto = require('crypto');
crypto.randomBytes(16, (err, buf) => {
  if (err) throw err;
  console.log(buf.length);
});
JS
    validator_assert_contains "$tmpdir/out" '16'
    ;;
  *)
    printf 'unknown libuv eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
