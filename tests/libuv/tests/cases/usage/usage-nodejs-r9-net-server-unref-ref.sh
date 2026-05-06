#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-net-server-unref-ref
# @title: Node.js net.Server unref does not block exit
# @description: Listens on a 127.0.0.1 TCP port, calls server.unref, and verifies the process exits naturally without an explicit close.
# @timeout: 60
# @tags: usage, net, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - >"$tmpdir/out" <<'JS'
const net = require('net');
const server = net.createServer();
server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  console.log('listening', port);
  server.unref();
});
JS

grep -q 'listening ' "$tmpdir/out"
