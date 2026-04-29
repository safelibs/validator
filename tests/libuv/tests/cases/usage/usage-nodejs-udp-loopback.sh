#!/usr/bin/env bash
# @testcase: usage-nodejs-udp-loopback
# @title: Node.js udp loopback
# @description: Runs Node.js udp loopback behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const dgram=require('dgram'); const s=dgram.createSocket('udp4'); s.on('message',m=>{console.log(m.toString()); s.close();}); s.bind(0,'127.0.0.1',()=>s.send(Buffer.from('udp-ok'),s.address().port,'127.0.0.1'));" "$tmpdir/node.txt"
