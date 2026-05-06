#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-net-server-getconnections
# @title: Node.js net.Server getConnections counts active sockets
# @description: Opens a TCP server on 127.0.0.1, makes two concurrent client connections and verifies server.getConnections reports two before all sockets are closed.
# @timeout: 60
# @tags: usage, net, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const net = require('net');
const assert = require('assert');

const sockets = [];
const server = net.createServer(s => { sockets.push(s); });
server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const c1 = net.connect(port, '127.0.0.1');
  const c2 = net.connect(port, '127.0.0.1');
  await Promise.all([
    new Promise(r => c1.on('connect', r)),
    new Promise(r => c2.on('connect', r)),
  ]);
  // Wait for server-side accept callbacks to register both sockets.
  await new Promise(r => setTimeout(r, 50));
  await new Promise((resolve, reject) => {
    server.getConnections((err, count) => {
      if (err) return reject(err);
      try { assert.equal(count, 2); resolve(); } catch (e) { reject(e); }
    });
  });
  c1.destroy(); c2.destroy();
  for (const s of sockets) s.destroy();
  server.close();
});
JS
