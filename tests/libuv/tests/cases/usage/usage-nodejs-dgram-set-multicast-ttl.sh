#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-set-multicast-ttl
# @title: Node.js dgram setMulticastTTL
# @description: Binds a dgram udp4 socket to loopback and exercises setMulticastTTL without joining a multicast group, then closes cleanly.
# @timeout: 120
# @tags: usage, nodejs, dgram
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-dgram-set-multicast-ttl"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const dgram = require('dgram');
const socket = dgram.createSocket('udp4');
socket.on('error', (err) => { console.error(err.stack || err); process.exit(1); });
socket.bind(0, '127.0.0.1', () => {
  try {
    socket.setMulticastTTL(4);
    socket.setMulticastLoopback(true);
  } catch (err) {
    console.error(err.stack || err);
    process.exit(1);
  }
  const addr = socket.address();
  if (addr.address !== '127.0.0.1' || !(addr.port > 0)) {
    console.error('bad addr ' + JSON.stringify(addr));
    process.exit(1);
  }
  console.log('multicast-ttl ok port=' + addr.port);
  socket.close();
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'multicast-ttl ok'
