#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing luv for Lua"
  lua5.4 - <<'LUA'
local uv = require("luv")
local fired = false
local timer = uv.new_timer()
timer:start(10, 0, function()
  fired = true
  timer:stop()
  timer:close()
end)
uv.run()
assert(fired)
LUA
}

main "$@"
