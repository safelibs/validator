#!/usr/bin/env bash
# @testcase: usage-nodejs-net-connect-localport-binding
# @title: Node.js net.connect localPort binding
# @description: Binds an outgoing net.connect to an OS-assigned localPort by passing localAddress and verifies the client's reported localPort is non-zero.
# @timeout: 120
# @tags: usage, nodejs, net
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-net-connect-localport-binding"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const net = require('net');
const server = net.createServer((socket) => { socket.end(); });
server.listen(0, '127.0.0.1', () => {
  const port = server.address().port;
  const client = net.connect({
    host: '127.0.0.1',
    port,
    localAddress: '127.0.0.1',
    localPort: 0,
  }, () => {
    const localPort = client.localPort;
    if (typeof localPort !== 'number' || localPort <= 0) {
      console.error('bad localPort=' + localPort);
      process.exit(1);
    }
    if (client.localAddress !== '127.0.0.1') {
      console.error('bad localAddress=' + client.localAddress);
      process.exit(1);
    }
    console.log('localport ok bound=' + (localPort > 0));
    client.end();
    server.close();
  });
  client.on('error', (err) => { console.error(err.stack || err); process.exit(1); });
});
server.on('error', (err) => { console.error(err.stack || err); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'localport ok bound=true'
