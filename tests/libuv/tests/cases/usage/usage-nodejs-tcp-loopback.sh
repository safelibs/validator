#!/usr/bin/env bash
# @testcase: usage-nodejs-tcp-loopback
# @title: Node.js tcp loopback
# @description: Runs Node.js tcp loopback behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const net=require('net'); const server=net.createServer(s=>s.end('pong')); server.listen(0,'127.0.0.1',()=>{net.createConnection(server.address().port,'127.0.0.1').on('data',d=>{console.log(d.toString()); server.close();});});" "$tmpdir/node.txt"
