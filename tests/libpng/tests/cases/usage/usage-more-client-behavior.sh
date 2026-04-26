#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

case "$case_id" in
  usage-netpbm-pnmflip-topbottom-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmflip -topbottom "$tmpdir/in.pnm" >"$tmpdir/flipped.pnm"
    pnmtopng "$tmpdir/flipped.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmcut-corner-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmcut 1 1 6 6 "$tmpdir/in.pnm" >"$tmpdir/cut.pnm"
    pnmtopng "$tmpdir/cut.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmscale-double-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmscale 2 "$tmpdir/in.pnm" >"$tmpdir/scaled.pnm"
    pnmtopng "$tmpdir/scaled.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pamchannel-green-png)
    pngtopam "$png" >"$tmpdir/in.pam"
    pamchannel -infile="$tmpdir/in.pam" 1 >"$tmpdir/green.pam"
    pamfile "$tmpdir/green.pam" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'by 1 maxval 255'
    ;;
  usage-netpbm-pnmfile-roundtrip-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmtopng "$tmpdir/in.pnm" >"$tmpdir/out.png"
    pngtopnm "$tmpdir/out.png" >"$tmpdir/out.pnm"
    pnmfile "$tmpdir/out.pnm" | tee "$tmpdir/out"
    grep -Eq '[0-9]+ by [0-9]+' "$tmpdir/out"
    ;;
  usage-pngquant-colors-two-png)
    pngquant --force --output "$tmpdir/out.png" 2 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-quality-low-png)
    pngquant --force --quality=1-20 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-speed-eleven-png)
    pngquant --force --speed 11 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-strip-output-png)
    pngquant --force --strip --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-posterize-two-png)
    pngquant --force --posterize 2 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  *)
    printf 'unknown libpng additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
