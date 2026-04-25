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
  usage-netpbm-pnmscale-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmscale 0.5 "$tmpdir/in.pnm" >"$tmpdir/scaled.pnm"
    pnmtopng "$tmpdir/scaled.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmflip-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmflip -leftright "$tmpdir/in.pnm" >"$tmpdir/flipped.pnm"
    pnmtopng "$tmpdir/flipped.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmcut-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmcut 0 0 8 8 "$tmpdir/in.pnm" >"$tmpdir/cut.pnm"
    pnmtopng "$tmpdir/cut.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmgamma-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmgamma 1.8 "$tmpdir/in.pnm" >"$tmpdir/gamma.pnm"
    pnmtopng "$tmpdir/gamma.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-netpbm-pnmdepth-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmdepth 15 "$tmpdir/in.pnm" >"$tmpdir/depth.pnm"
    pnmtopng "$tmpdir/depth.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-nofs-png)
    pngquant --force --nofs --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-floyd-png)
    pngquant --force --floyd=0.5 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-colors-eight-png)
    pngquant --force --output "$tmpdir/out.png" 8 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-ext-png)
    cp "$png" "$tmpdir/input.png"
    (cd "$tmpdir" && pngquant --force --ext .quant.png 16 input.png)
    assert_png "$tmpdir/input.quant.png"
    ;;
  usage-pngquant-skip-if-larger-png)
    if pngquant --skip-if-larger --force --output "$tmpdir/out.png" 256 "$png"; then
      assert_png "$tmpdir/out.png"
    else
      test ! -e "$tmpdir/out.png"
      printf 'pngquant skipped larger output\n'
    fi
    ;;
  usage-netpbm-pnmfile-png)
    pngtopnm "$png" >"$tmpdir/in.pnm"
    pnmfile "$tmpdir/in.pnm" | tee "$tmpdir/out"
    grep -Eq '[0-9]+ by [0-9]+' "$tmpdir/out"
    ;;
  usage-netpbm-pamfile-png)
    pngtopam "$png" >"$tmpdir/in.pam"
    pamfile "$tmpdir/in.pam" | tee "$tmpdir/out"
    grep -Eq '[0-9]+ by [0-9]+' "$tmpdir/out"
    ;;
  usage-netpbm-pamchannel-red-png)
    pngtopam "$png" >"$tmpdir/in.pam"
    pamchannel -infile="$tmpdir/in.pam" 0 >"$tmpdir/red.pam"
    pamfile "$tmpdir/red.pam" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'by 1 maxval 255'
    ;;
  usage-netpbm-pamchannel-blue-png)
    pngtopam "$png" >"$tmpdir/in.pam"
    pamchannel -infile="$tmpdir/in.pam" 2 >"$tmpdir/blue.pam"
    pamfile "$tmpdir/blue.pam" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'by 1 maxval 255'
    ;;
  usage-netpbm-pamtopnm-roundtrip-png)
    pngtopam "$png" >"$tmpdir/in.pam"
    pamtopnm "$tmpdir/in.pam" >"$tmpdir/out.pnm"
    pnmtopng "$tmpdir/out.pnm" >"$tmpdir/out.png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-colors-four-png)
    pngquant --force --output "$tmpdir/out.png" 4 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-quality-range-png)
    pngquant --force --quality=40-80 --output "$tmpdir/out.png" 32 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-speed-one-png)
    pngquant --force --speed 1 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  usage-pngquant-verbose-png)
    pngquant --verbose --force --output "$tmpdir/out.png" 16 "$png" >"$tmpdir/out.log" 2>&1
    assert_png "$tmpdir/out.png"
    test -s "$tmpdir/out.log"
    ;;
  usage-pngquant-floyd-zero-png)
    pngquant --force --floyd=0 --output "$tmpdir/out.png" 16 "$png"
    assert_png "$tmpdir/out.png"
    ;;
  *)
    printf 'unknown libpng extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
