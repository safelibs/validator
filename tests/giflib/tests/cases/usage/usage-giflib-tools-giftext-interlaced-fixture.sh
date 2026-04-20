#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"

giftext "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
grep -iq 'interlace' "$tmpdir/out" || {
  printf 'expected giftext output to mention interlace\n' >&2
  sed -n '1,120p' "$tmpdir/out" >&2
  exit 1
}
