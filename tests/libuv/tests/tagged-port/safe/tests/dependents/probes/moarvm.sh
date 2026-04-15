#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing MoarVM"
  raku -e 'my $p = Promise.in(0.1).then({ say q[ok] }); await $p;' >/tmp/moar.out
  grep -qx 'ok' /tmp/moar.out
}

main "$@"
