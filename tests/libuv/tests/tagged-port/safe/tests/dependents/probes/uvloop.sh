#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing uvloop"
  python3 - <<'PY'
import asyncio
import uvloop

async def main():
    server = await asyncio.start_server(lambda r, w: (w.write(b"pong"), w.close()), "127.0.0.1", 0)
    port = server.sockets[0].getsockname()[1]
    reader, writer = await asyncio.open_connection("127.0.0.1", port)
    data = await reader.read()
    assert data == b"pong"
    writer.close()
    await writer.wait_closed()
    server.close()
    await server.wait_closed()

uvloop.install()
asyncio.run(main())
PY
}

main "$@"
