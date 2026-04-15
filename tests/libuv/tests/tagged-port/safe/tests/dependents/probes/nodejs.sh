#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing Node.js"
  node <<'NODE'
const fs = require("fs");
const net = require("net");
const os = require("os");
const path = require("path");

const file = path.join(os.tmpdir(), "libuv-node-test.txt");
fs.writeFileSync(file, "ok");

const server = net.createServer((socket) => socket.end("pong"));
server.listen(0, "127.0.0.1", () => {
  const { port } = server.address();
  const client = net.createConnection({ port, host: "127.0.0.1" });
  let data = "";
  client.on("data", (chunk) => { data += chunk; });
  client.on("end", () => {
    if (data !== "pong") {
      process.exit(2);
    }
    fs.readFile(file, "utf8", (err, text) => {
      if (err || text !== "ok") {
        process.exit(3);
      }
      setTimeout(() => server.close(() => process.exit(0)), 10);
    });
  });
});
NODE
}

main "$@"
