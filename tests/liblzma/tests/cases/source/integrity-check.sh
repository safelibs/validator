#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'integrity\n' >"$tmpdir/plain"; xz --check=crc64 -c "$tmpdir/plain" >"$tmpdir/a.xz"; xz --test "$tmpdir/a.xz"; xz --list --verbose "$tmpdir/a.xz" | tee "$tmpdir/list"; grep -i CRC64 "$tmpdir/list"
