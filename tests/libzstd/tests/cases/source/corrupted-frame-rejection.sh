#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'not a zstd frame\n' >"$tmpdir/bad.zst"
if zstd -t "$tmpdir/bad.zst" >"$tmpdir/log" 2>&1; then
  cat "$tmpdir/log"
  echo 'malformed zstd frame unexpectedly tested cleanly' >&2
  exit 1
fi
cat "$tmpdir/log"
