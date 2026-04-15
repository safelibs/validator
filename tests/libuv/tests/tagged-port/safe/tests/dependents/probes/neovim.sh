#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing Neovim"
  nvim --headless --clean \
    '+lua local uv=vim.uv or vim.loop; assert(uv); local fired=false; local timer=uv.new_timer(); timer:start(10,0,function() fired=true; timer:stop(); timer:close(); vim.schedule(function() assert(fired); vim.cmd("qall!") end) end)'
}

main "$@"
