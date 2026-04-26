#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$case_id" "$tmpdir" <<'JS'
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const crypto = require('crypto');
const child_process = require('child_process');
const net = require('net');
const dgram = require('dgram');
const zlib = require('zlib');
const { Readable } = require('stream');

const caseId = process.argv[2];
const tmpdir = process.argv[3];

async function main() {
  if (caseId === 'usage-nodejs-fs-access') {
    const file = path.join(tmpdir, 'access.txt');
    await fsp.writeFile(file, 'access payload\n');
    await fsp.access(file);
    console.log('access');
  } else if (caseId === 'usage-nodejs-fs-rename') {
    const source = path.join(tmpdir, 'source.txt');
    const dest = path.join(tmpdir, 'dest.txt');
    await fsp.writeFile(source, 'rename payload\n');
    await fsp.rename(source, dest);
    console.log((await fsp.readFile(dest, 'utf8')).trim());
  } else if (caseId === 'usage-nodejs-fs-append-file') {
    const file = path.join(tmpdir, 'append.txt');
    await fsp.writeFile(file, 'alpha\n');
    await fsp.appendFile(file, 'beta\n');
    console.log((await fsp.readFile(file, 'utf8')).trim().replace(/\n/g, ','));
  } else if (caseId === 'usage-nodejs-crypto-hmac') {
    const digest = crypto.createHmac('sha256', 'key').update('payload').digest('hex');
    if (digest.length !== 64) throw new Error(digest);
    console.log(digest.slice(0, 16));
  } else if (caseId === 'usage-nodejs-child-process-spawnsync') {
    const result = child_process.spawnSync('/bin/printf', ['sync payload\n'], { encoding: 'utf8' });
    if (result.status !== 0) throw new Error(String(result.status));
    console.log(result.stdout.trim());
  } else if (caseId === 'usage-nodejs-timers-microtask-order') {
    const events = [];
    await new Promise((resolve) => {
      queueMicrotask(() => events.push('microtask'));
      setTimeout(() => { events.push('timeout'); resolve(); }, 5);
    });
    if (events.join(',') !== 'microtask,timeout') throw new Error(events.join(','));
    console.log(events.join(','));
  } else if (caseId === 'usage-nodejs-net-server-close-callback') {
    const closed = await new Promise((resolve, reject) => {
      const server = net.createServer();
      server.listen(0, '127.0.0.1', () => server.close(() => resolve(true)));
      server.on('error', reject);
    });
    if (!closed) throw new Error('close');
    console.log('closed');
  } else if (caseId === 'usage-nodejs-dgram-connect-send') {
    await new Promise((resolve, reject) => {
      const server = dgram.createSocket('udp4');
      server.on('message', (msg) => {
        if (msg.toString() !== 'udp-connect') reject(new Error(msg.toString()));
        server.close();
        resolve();
      });
      server.on('error', reject);
      server.bind(0, '127.0.0.1', () => {
        const client = dgram.createSocket('udp4');
        client.connect(server.address().port, '127.0.0.1', (err) => {
          if (err) return reject(err);
          client.send(Buffer.from('udp-connect'), (err2) => {
            client.close();
            if (err2) reject(err2);
          });
        });
      });
    });
    console.log('udp-connect');
  } else if (caseId === 'usage-nodejs-stream-readable-collect') {
    const lines = [];
    for await (const chunk of Readable.from(['alpha', 'beta'])) lines.push(chunk);
    if (lines.join(',') !== 'alpha,beta') throw new Error(lines.join(','));
    console.log(lines.join(','));
  } else if (caseId === 'usage-nodejs-zlib-gzipsync') {
    const compressed = zlib.gzipSync(Buffer.from('gzipsync payload\n'));
    const plain = zlib.gunzipSync(compressed).toString('utf8');
    if (plain !== 'gzipsync payload\n') throw new Error(plain);
    console.log(plain.trim());
  } else {
    throw new Error(`unknown libuv even-more usage case: ${caseId}`);
  }
}

main().catch((err) => {
  console.error(err && err.stack || err);
  process.exit(1);
});
JS
