#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-readdir-names
# @title: Node.js fs readdir names
# @description: Lists directory children through fs.promises.readdir and verifies the expected filenames are returned.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-fs-readdir-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - "$case_id" "$tmpdir" <<'JS'
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const crypto = require('crypto');
const zlib = require('zlib');
const child_process = require('child_process');
const net = require('net');
const dgram = require('dgram');

const caseId = process.argv[2];
const tmpdir = process.argv[3];

async function main() {
  if (caseId === 'usage-nodejs-fs-readdir-names') {
    await fsp.writeFile(path.join(tmpdir, 'alpha.txt'), 'a');
    await fsp.writeFile(path.join(tmpdir, 'beta.txt'), 'b');
    const names = (await fsp.readdir(tmpdir)).sort();
    if (names.join(',') !== 'alpha.txt,beta.txt') throw new Error(names.join(','));
    console.log(names.join(','));
  } else if (caseId === 'usage-nodejs-fs-realpath') {
    const dir = path.join(tmpdir, 'real');
    await fsp.mkdir(dir);
    const file = path.join(dir, 'file.txt');
    await fsp.writeFile(file, 'realpath payload\n');
    const real = await fsp.realpath(file);
    if (!real.endsWith(path.join('real', 'file.txt'))) throw new Error(real);
    console.log(real);
  } else if (caseId === 'usage-nodejs-fs-utimes') {
    const file = path.join(tmpdir, 'time.txt');
    await fsp.writeFile(file, 'time payload\n');
    const atime = new Date(1000);
    const mtime = new Date(2000);
    await fsp.utimes(file, atime, mtime);
    const stat = await fsp.stat(file);
    if (stat.mtimeMs < 1000) throw new Error(String(stat.mtimeMs));
    console.log(Math.floor(stat.mtimeMs));
  } else if (caseId === 'usage-nodejs-crypto-scrypt') {
    const key = await new Promise((resolve, reject) => {
      crypto.scrypt('password', 'salt', 16, (err, buf) => err ? reject(err) : resolve(buf));
    });
    if (key.length !== 16) throw new Error(String(key.length));
    console.log('scrypt', key.length);
  } else if (caseId === 'usage-nodejs-child-process-exec') {
    const out = await new Promise((resolve, reject) => {
      child_process.exec('printf exec-payload\\n', (err, stdout) => err ? reject(err) : resolve(stdout));
    });
    if (!out.includes('exec-payload')) throw new Error(out);
    console.log(out.trim());
  } else if (caseId === 'usage-nodejs-timers-setinterval') {
    const events = [];
    await new Promise((resolve) => {
      const timer = setInterval(() => {
        events.push(`tick${events.length + 1}`);
        if (events.length === 2) {
          clearInterval(timer);
          resolve();
        }
      }, 5);
    });
    if (events.join(',') !== 'tick1,tick2') throw new Error(events.join(','));
    console.log(events.join(','));
  } else if (caseId === 'usage-nodejs-dgram-bind-address') {
    const socket = dgram.createSocket('udp4');
    await new Promise((resolve, reject) => {
      socket.bind(0, '127.0.0.1', resolve);
      socket.on('error', reject);
    });
    const address = socket.address();
    socket.close();
    if (address.address !== '127.0.0.1') throw new Error(address.address);
    console.log(address.address, address.port);
  } else if (caseId === 'usage-nodejs-net-client-local-address') {
    await new Promise((resolve, reject) => {
      const server = net.createServer((socket) => socket.end('done\n'));
      server.listen(0, '127.0.0.1', () => {
        const port = server.address().port;
        const client = net.createConnection({ port, host: '127.0.0.1' }, () => {
          if (client.localAddress !== '127.0.0.1') reject(new Error(client.localAddress));
        });
        let body = '';
        client.on('data', (chunk) => body += chunk);
        client.on('end', () => {
          server.close();
          body === 'done\n' ? resolve() : reject(new Error(body));
        });
        client.on('error', reject);
      });
      server.on('error', reject);
    });
    console.log('127.0.0.1');
  } else if (caseId === 'usage-nodejs-zlib-gunzip-buffer') {
    const compressed = zlib.gzipSync(Buffer.from('gunzip payload\n'));
    const plain = zlib.gunzipSync(compressed).toString('utf8');
    if (plain !== 'gunzip payload\n') throw new Error(plain);
    console.log(plain.trim());
  } else if (caseId === 'usage-nodejs-fs-copy-file') {
    const source = path.join(tmpdir, 'source.txt');
    const dest = path.join(tmpdir, 'dest.txt');
    await fsp.writeFile(source, 'copy payload\n');
    await fsp.copyFile(source, dest);
    const body = await fsp.readFile(dest, 'utf8');
    if (body !== 'copy payload\n') throw new Error(body);
    console.log(body.trim());
  } else {
    throw new Error(`unknown libuv additional usage case: ${caseId}`);
  }
}

main().catch((err) => {
  console.error(err && err.stack || err);
  process.exit(1);
});
JS
