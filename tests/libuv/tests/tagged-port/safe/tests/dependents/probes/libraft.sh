#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing libraft"
  mkdir -p /tmp/raft-submit
  raft-benchmark submit -d /tmp/raft-submit -s 65536 >/tmp/raft-submit.out
  grep -q '"submit:' /tmp/raft-submit.out
}

main "$@"
