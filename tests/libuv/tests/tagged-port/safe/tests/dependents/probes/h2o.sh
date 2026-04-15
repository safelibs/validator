#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing H2O libuv library"
  (
    set -euo pipefail
    local dir
    dir="$(mktemp -d /tmp/h2o-test.XXXXXX)"
    mkdir -p "${dir}/root"
    printf 'hello\n' >"${dir}/root/index.txt"
    chmod 755 "${dir}" "${dir}/root"
    chmod 644 "${dir}/root/index.txt"
    cat >"${dir}/h2o.conf" <<CFG
server-name: "h2o-test"
listen:
  host: 127.0.0.1
  port: 8081
hosts:
  default:
    paths:
      /:
        file.dir: ${dir}/root
CFG
    h2o -c "${dir}/h2o.conf" >"${dir}/h2o.log" 2>&1 &
    pid=$!
    trap 'kill "${pid}" 2>/dev/null || true; wait "${pid}" 2>/dev/null || true' EXIT
    for _ in $(seq 1 50); do
      if curl -fsS http://127.0.0.1:8081/index.txt >"${dir}/out" 2>/dev/null && \
         grep -qx 'hello' "${dir}/out"; then
        exit 0
      fi
      sleep 0.2
    done
    cat "${dir}/h2o.log"
    exit 1
  )
}

main "$@"
