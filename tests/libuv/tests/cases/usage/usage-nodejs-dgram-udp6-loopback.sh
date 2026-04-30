#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-udp6-loopback
# @title: Node.js dgram udp6 loopback over ::1
# @description: Creates a dgram udp6 socket bound to ::1 and round trips a datagram to itself, verifying the IPv6 loopback transport carried the payload.
# @timeout: 180
# @tags: usage, nodejs, dgram, ipv6
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const dgram = require('dgram');

const payload = Buffer.from('udp6 loopback payload');

const server = dgram.createSocket('udp6');

function skip(reason) {
  console.log('OK udp6 skipped reason=%s', reason);
  try { server.close(); } catch (_) { /* ignore */ }
  process.exit(0);
}

server.on('error', (err) => {
  if (err && (err.code === 'EAFNOSUPPORT' || err.code === 'EADDRNOTAVAIL' || err.code === 'EINVAL')) {
    skip(err.code);
    return;
  }
  console.error(err.stack || err);
  process.exit(1);
});

server.on('message', (msg, rinfo) => {
  try {
    assert.ok(msg.equals(payload), 'message mismatch');
    assert.strictEqual(rinfo.family, 'IPv6');
    console.log('OK udp6 family=%s len=%d', rinfo.family, msg.length);
  } finally {
    server.close();
  }
});

try {
  server.bind(0, '::1', () => {
    const port = server.address().port;
    const client = dgram.createSocket('udp6');
    client.on('error', (err) => {
      client.close();
      if (err && (err.code === 'EAFNOSUPPORT' || err.code === 'EADDRNOTAVAIL')) {
        skip(err.code);
        return;
      }
      console.error(err.stack || err);
      process.exit(1);
    });
    client.send(payload, port, '::1', (err) => {
      if (err) {
        client.close();
        if (err.code === 'EAFNOSUPPORT' || err.code === 'EADDRNOTAVAIL') {
          skip(err.code);
          return;
        }
        console.error(err.stack || err);
        process.exit(1);
      }
    });
  });
} catch (err) {
  if (err && (err.code === 'EAFNOSUPPORT' || err.code === 'EADDRNOTAVAIL' || err.code === 'EINVAL')) {
    skip(err.code);
  } else {
    throw err;
  }
}
JS

node "$tmpdir/run.js" >"$tmpdir/out"

grep -Eq 'OK udp6 (family=IPv6 len=21|skipped reason=)' "$tmpdir/out" || {
  printf 'expected udp6 ok or skip line in output\n' >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  exit 1
}
