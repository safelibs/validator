#!/usr/bin/env bash
# @testcase: usage-nodejs-randombytes-async
# @title: Node.js async randomBytes
# @description: Runs asynchronous crypto.randomBytes and verifies callback data length.
# @timeout: 180
# @tags: usage, event-loop, crypto
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-randombytes-async"
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
const readline = require('readline');
const { Readable } = require('stream');
const { pipeline } = require('stream/promises');
const timers = require('timers/promises');

const caseId = process.argv[2];
const tmpdir = process.argv[3];

async function main() {
  if (caseId === 'usage-nodejs-fs-promises') {
    const file = path.join(tmpdir, 'promise.txt');
    await fsp.writeFile(file, 'promise payload\n');
    const body = await fsp.readFile(file, 'utf8');
    if (!body.includes('promise payload')) throw new Error(body);
    console.log(body.trim());
  } else if (caseId === 'usage-nodejs-opendir') {
    await fsp.writeFile(path.join(tmpdir, 'alpha.txt'), 'a');
    const dir = await fsp.opendir(tmpdir);
    const names = [];
    for await (const entry of dir) names.push(entry.name);
    if (!names.includes('alpha.txt')) throw new Error(names.join(','));
    console.log(names.sort().join(','));
  } else if (caseId === 'usage-nodejs-setimmediate') {
    await new Promise((resolve) => setImmediate(resolve));
    console.log('immediate');
  } else if (caseId === 'usage-nodejs-nexttick-timeout') {
    const events = [];
    await new Promise((resolve) => {
      process.nextTick(() => events.push('tick'));
      setTimeout(() => { events.push('timeout'); resolve(); }, 5);
    });
    if (events.join(',') !== 'tick,timeout') throw new Error(events.join(','));
    console.log(events.join(','));
  } else if (caseId === 'usage-nodejs-randombytes-async') {
    const buf = await new Promise((resolve, reject) => crypto.randomBytes(16, (err, data) => err ? reject(err) : resolve(data)));
    if (buf.length !== 16) throw new Error(String(buf.length));
    console.log('random', buf.length);
  } else if (caseId === 'usage-nodejs-zlib-deflate') {
    const input = Buffer.from('zlib payload');
    const compressed = await new Promise((resolve, reject) => zlib.deflate(input, (err, data) => err ? reject(err) : resolve(data)));
    const plain = await new Promise((resolve, reject) => zlib.inflate(compressed, (err, data) => err ? reject(err) : resolve(data)));
    if (plain.toString() !== 'zlib payload') throw new Error(plain.toString());
    console.log(plain.toString());
  } else if (caseId === 'usage-nodejs-spawn-stdio') {
    const out = await new Promise((resolve, reject) => {
      const child = child_process.spawn('/bin/printf', ['spawn payload\\n']);
      let data = '';
      child.stdout.on('data', chunk => data += chunk);
      child.on('error', reject);
      child.on('close', code => code === 0 ? resolve(data) : reject(new Error(String(code))));
    });
    if (!out.includes('spawn payload')) throw new Error(out);
    console.log(out.trim());
  } else if (caseId === 'usage-nodejs-net-echo') {
    await new Promise((resolve, reject) => {
      const server = net.createServer(socket => socket.pipe(socket));
      server.listen(0, '127.0.0.1', () => {
        const port = server.address().port;
        const client = net.createConnection({ port, host: '127.0.0.1' }, () => client.write('echo payload'));
        let data = '';
        client.on('data', chunk => { data += chunk; client.end(); });
        client.on('end', () => { server.close(); data === 'echo payload' ? resolve() : reject(new Error(data)); });
      });
      server.on('error', reject);
    });
    console.log('echo payload');
  } else if (caseId === 'usage-nodejs-dgram-connect') {
    await new Promise((resolve, reject) => {
      const server = dgram.createSocket('udp4');
      server.on('message', (msg) => { if (msg.toString() !== 'udp payload') reject(new Error(msg.toString())); server.close(); resolve(); });
      server.bind(0, '127.0.0.1', () => {
        const client = dgram.createSocket('udp4');
        client.send(Buffer.from('udp payload'), server.address().port, '127.0.0.1', (err) => { client.close(); if (err) reject(err); });
      });
    });
    console.log('udp payload');
  } else if (caseId === 'usage-nodejs-readline-stream') {
    const rl = readline.createInterface({ input: Readable.from(['alpha\n', 'beta\n']) });
    const lines = [];
    for await (const line of rl) lines.push(line);
    if (lines.length !== 2 || lines[1] !== 'beta') throw new Error(lines.join(','));
    console.log(lines.join(','));
  } else if (caseId === 'usage-nodejs-fs-mkdir-recursive') {
    const dir = path.join(tmpdir, 'one', 'two', 'three');
    await fsp.mkdir(dir, { recursive: true });
    const stat = await fsp.stat(dir);
    if (!stat.isDirectory()) throw new Error('not a directory');
    console.log(path.relative(tmpdir, dir));
  } else if (caseId === 'usage-nodejs-fs-stat-size') {
    const file = path.join(tmpdir, 'stat.txt');
    await fsp.writeFile(file, 'stat payload\n');
    const stat = await fsp.stat(file);
    if (stat.size !== 13) throw new Error(String(stat.size));
    console.log('size', stat.size);
  } else if (caseId === 'usage-nodejs-execfile') {
    const out = await new Promise((resolve, reject) => {
      child_process.execFile('/bin/printf', ['execfile payload\\n'], (err, stdout) => err ? reject(err) : resolve(stdout));
    });
    if (!out.includes('execfile payload')) throw new Error(out);
    console.log(out.trim());
  } else if (caseId === 'usage-nodejs-stream-pipeline') {
    const file = path.join(tmpdir, 'pipeline.txt');
    await pipeline(Readable.from(['pipe ', 'payload\n']), fs.createWriteStream(file));
    const body = await fsp.readFile(file, 'utf8');
    if (body !== 'pipe payload\n') throw new Error(body);
    console.log(body.trim());
  } else if (caseId === 'usage-nodejs-timers-promises') {
    const value = await timers.setTimeout(5, 'timer done');
    if (value !== 'timer done') throw new Error(String(value));
    console.log(value);
  } else if (caseId === 'usage-nodejs-crypto-createhash') {
    const digest = crypto.createHash('sha256').update('payload').digest('hex');
    if (!digest.startsWith('239f59ed')) throw new Error(digest);
    console.log(digest.slice(0, 16));
  } else if (caseId === 'usage-nodejs-zlib-gzip-stream') {
    const gz = path.join(tmpdir, 'payload.gz');
    await pipeline(Readable.from(['stream payload\n']), zlib.createGzip(), fs.createWriteStream(gz));
    const plain = zlib.gunzipSync(await fsp.readFile(gz)).toString('utf8');
    if (plain !== 'stream payload\n') throw new Error(plain);
    console.log(plain.trim());
  } else if (caseId === 'usage-nodejs-net-server-address') {
    const port = await new Promise((resolve, reject) => {
      const server = net.createServer();
      server.listen(0, '127.0.0.1', () => {
        const address = server.address();
        server.close(() => resolve(address.port));
      });
      server.on('error', reject);
    });
    if (!(port > 0)) throw new Error(String(port));
    console.log('port', port);
  } else if (caseId === 'usage-nodejs-dgram-two-messages') {
    await new Promise((resolve, reject) => {
      let count = 0;
      const server = dgram.createSocket('udp4');
      server.on('message', (msg) => {
        count += 1;
        if (count === 2) {
          server.close();
          resolve();
        } else if (msg.toString() !== 'first' && msg.toString() !== 'second') {
          reject(new Error(msg.toString()));
        }
      });
      server.bind(0, '127.0.0.1', () => {
        const client = dgram.createSocket('udp4');
        client.send(Buffer.from('first'), server.address().port, '127.0.0.1');
        client.send(Buffer.from('second'), server.address().port, '127.0.0.1', () => client.close());
      });
      server.on('error', reject);
    });
    console.log('messages', 2);
  } else if (caseId === 'usage-nodejs-readfile-buffer') {
    const file = path.join(tmpdir, 'buffer.txt');
    await fsp.writeFile(file, 'buffer payload\n');
    const body = await fsp.readFile(file);
    if (!Buffer.isBuffer(body) || body.toString('utf8') !== 'buffer payload\n') throw new Error(String(body));
    console.log('buffer', body.length);
  } else {
    throw new Error(`unknown libuv extra usage case: ${caseId}`);
  }
}

main().catch((err) => { console.error(err && err.stack || err); process.exit(1); });
JS
