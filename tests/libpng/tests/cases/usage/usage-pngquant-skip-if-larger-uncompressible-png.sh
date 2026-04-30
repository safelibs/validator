#!/usr/bin/env bash
# @testcase: usage-pngquant-skip-if-larger-uncompressible-png
# @title: pngquant --skip-if-larger on small uncompressible PNG
# @description: Runs pngquant --skip-if-larger against a small near-uncompressible 2x2 random-pixel PNG and accepts either a successful smaller result (rc=0) or pngquant's larger-output discard exit (rc=98 / rc=99) without writing a file.
# @timeout: 120
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-skip-if-larger-uncompressible-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a tiny 2x2 RGB PNG with four very different pixels — there is little
# room for pngquant's palette+filter pipeline to shrink the output below the
# original PNG's stream size, so --skip-if-larger may legitimately decline.
cat >"$tmpdir/seed.ppm" <<'EOF'
P3
2 2
255
0 0 0     255 255 255
12 200 38 240 17 130
EOF
pnmtopng "$tmpdir/seed.ppm" >"$tmpdir/seed.png"
file "$tmpdir/seed.png" | tee "$tmpdir/seed.file"
validator_assert_contains "$tmpdir/seed.file" 'PNG image data'
seed_size=$(stat -c %s "$tmpdir/seed.png")

set +e
pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$tmpdir/seed.png"
rc=$?
set -e
printf 'pngquant exit=%s seed_size=%s\n' "$rc" "$seed_size"

case "$rc" in
  0)
    file "$tmpdir/out.png" | tee "$tmpdir/file"
    validator_assert_contains "$tmpdir/file" 'PNG image data'
    out_size=$(stat -c %s "$tmpdir/out.png")
    # --skip-if-larger guarantees the surviving output is no larger than seed.
    if (( out_size > seed_size )); then
      printf '--skip-if-larger violated: out=%s seed=%s\n' "$out_size" "$seed_size" >&2
      exit 1
    fi
    ;;
  98|99)
    test ! -e "$tmpdir/out.png"
    printf 'pngquant declined uncompressible input (rc=%s)\n' "$rc"
    ;;
  *)
    printf 'unexpected pngquant exit status: %s\n' "$rc" >&2
    exit 1
    ;;
esac
