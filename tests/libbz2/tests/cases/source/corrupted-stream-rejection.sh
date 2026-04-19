#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'payload\n' >"$tmpdir/plain"; bzip2 -c "$tmpdir/plain" >"$tmpdir/plain.bz2"; cp "$tmpdir/plain.bz2" "$tmpdir/bad.bz2"; printf '\000' | dd of="$tmpdir/bad.bz2" bs=1 seek=10 conv=notrunc status=none; if bunzip2 -c "$tmpdir/bad.bz2" >"$tmpdir/out" 2>"$tmpdir/log"; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
