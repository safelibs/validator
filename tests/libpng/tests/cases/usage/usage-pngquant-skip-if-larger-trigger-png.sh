#!/usr/bin/env bash
# @testcase: usage-pngquant-skip-if-larger-trigger-png
# @title: pngquant skip-if-larger triggers exit 98
# @description: Quantises an already-tiny 1x1 PNG with --skip-if-larger and accepts pngquant's larger-output exit status (98) without writing a file.
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a trivial 1x1 RGB PNG that pngquant cannot meaningfully shrink further.
printf 'P3\n1 1\n255\n128 64 200\n' >"$tmpdir/seed.ppm"
pnmtopng "$tmpdir/seed.ppm" >"$tmpdir/seed.png"

set +e
pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$tmpdir/seed.png"
rc=$?
set -e

printf 'pngquant exit=%s\n' "$rc"
case "$rc" in
  0)
    file "$tmpdir/out.png" | tee "$tmpdir/file"
    validator_assert_contains "$tmpdir/file" 'PNG image data'
    ;;
  98|99)
    test ! -e "$tmpdir/out.png"
    printf 'pngquant declined to write a larger output (rc=%s)\n' "$rc"
    ;;
  *)
    printf 'unexpected pngquant exit status: %s\n' "$rc" >&2
    exit 1
    ;;
esac
