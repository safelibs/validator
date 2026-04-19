#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'corrupt\n' >"$tmpdir/plain"; xz -c "$tmpdir/plain" >"$tmpdir/a.xz"; cp "$tmpdir/a.xz" "$tmpdir/bad.xz"; printf '\377' | dd of="$tmpdir/bad.xz" bs=1 seek=12 conv=notrunc status=none; if xz --test "$tmpdir/bad.xz" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
