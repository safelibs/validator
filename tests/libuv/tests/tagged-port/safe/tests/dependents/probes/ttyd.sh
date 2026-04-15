#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing ttyd"
  (
    set -euo pipefail
    local dir
    dir="$(mktemp -d /tmp/ttyd-test.XXXXXX)"
    ttyd -p 7681 sh -lc 'printf ready; sleep 5' >"${dir}/ttyd.log" 2>&1 &
    pid=$!
    trap 'kill "${pid}" 2>/dev/null || true; wait "${pid}" 2>/dev/null || true' EXIT
    for _ in $(seq 1 50); do
      if curl -fsS http://127.0.0.1:7681/ >"${dir}/index.html" 2>/dev/null; then
        break
      fi
      sleep 0.2
    done
    grep -q 'ttyd' "${dir}/index.html"
  )
}

main "$@"
