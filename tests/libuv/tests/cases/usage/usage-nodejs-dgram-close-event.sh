#!/usr/bin/env bash
# @testcase: usage-nodejs-dgram-close-event
# @title: Node.js dgram close event
# @description: Opens and closes a UDP socket with Node.js dgram and verifies the close event is emitted.
# @timeout: 180
# @tags: usage, nodejs, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-dgram-close-event"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const dgram = require('dgram');
const socket = dgram.createSocket('udp4');
socket.on('close', () => {
  console.log('closed');
});
socket.bind(0, '127.0.0.1', () => socket.close());
JS
validator_assert_contains "$tmpdir/out" 'closed'
