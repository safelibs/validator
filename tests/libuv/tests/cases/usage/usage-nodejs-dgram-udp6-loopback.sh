#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-udp6-loopback
# @title: Node.js dgram udp6 loopback over ::1
# @description: Creates a dgram udp6 socket bound to ::1 and round trips a datagram to itself, verifying the IPv6 loopback transport carries the payload.
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

// Hard timeout: fail loudly rather than hang the harness if ::1 loopback
// datagrams are silently dropped (which would indicate a broken IPv6 stack
// in the validator container).
const watchdog = setTimeout(() => {
  console.error('udp6 loopback timed out waiting for the receiver');
  try { server.close(); } catch (_) { /* ignore */ }
  process.exit(1);
}, 30000);

server.on('error', (err) => {
  console.error(err.stack || err);
  process.exit(1);
});

server.on('message', (msg, rinfo) => {
  try {
    assert.ok(msg.equals(payload), 'message mismatch');
    assert.strictEqual(rinfo.family, 'IPv6');
    console.log('OK udp6 family=%s len=%d', rinfo.family, msg.length);
  } finally {
    clearTimeout(watchdog);
    server.close();
  }
});

server.bind(0, '::1', () => {
  const port = server.address().port;
  const client = dgram.createSocket('udp6');
  client.on('error', (err) => {
    client.close();
    console.error(err.stack || err);
    process.exit(1);
  });
  client.send(payload, port, '::1', (err) => {
    if (err) {
      client.close();
      console.error(err.stack || err);
      process.exit(1);
    } else {
      client.close();
    }
  });
});
JS

node "$tmpdir/run.js" >"$tmpdir/out"

grep -Eq 'OK udp6 family=IPv6 len=21' "$tmpdir/out" || {
  printf 'expected udp6 ok line in output\n' >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  exit 1
}
