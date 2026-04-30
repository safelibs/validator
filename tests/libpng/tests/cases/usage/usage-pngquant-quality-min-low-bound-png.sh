#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-min-low-bound-png
# @title: pngquant --quality min lower bound PNG
# @description: Runs pngquant with a low minimum quality (--quality=10-100) on basn2c08.png and verifies a valid PNG is produced with the same dimensions; also covers the low-bound discard semantics by accepting exit code 99 if pngquant declines the low quality result.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-quality-min-low-bound-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

set +e
pngquant --quality=10-100 --force --output "$tmpdir/out.png" 256 "$png"
rc=$?
set -e
printf 'pngquant exit=%s\n' "$rc"

case "$rc" in
  0)
    file "$tmpdir/out.png" | tee "$tmpdir/file"
    validator_assert_contains "$tmpdir/file" 'PNG image data'
    pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
    pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
    validator_assert_contains "$tmpdir/pamfile" '32 by 32'
    ;;
  99)
    # Low-bound says: if min cannot be met, drop the file. Accept that path too.
    test ! -e "$tmpdir/out.png"
    printf 'pngquant declined: result quality below min (rc=99)\n'
    ;;
  *)
    printf 'unexpected pngquant exit status: %s\n' "$rc" >&2
    exit 1
    ;;
esac
