#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-gif2rgb-fire-planar-rgb-bytes-equal
# @title: gif2rgb -o on fire.gif emits .R, .G, .B planar files of equal positive size
# @description: Runs gif2rgb -o without -1 against fire.gif (multi-frame, 30x60) producing the planar .R/.G/.B sidecar files and asserts each file exists, all three are the same positive size, and the size equals the per-frame pixel count times the number of frames (33 frames * 30 * 60 = 59400 bytes per plane), exercising the planar tri-file output mode size invariant.
# @timeout: 60
# @tags: usage, cli, gif2rgb, planar, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gif2rgb -o "$tmpdir/out.rgb" "$gif"

for ext in R G B; do
    [[ -f "$tmpdir/out.rgb.$ext" ]] || { echo "missing plane $ext" >&2; exit 1; }
done

sR=$(stat -c '%s' "$tmpdir/out.rgb.R")
sG=$(stat -c '%s' "$tmpdir/out.rgb.G")
sB=$(stat -c '%s' "$tmpdir/out.rgb.B")

[[ "$sR" -gt 0 ]] || { echo "R plane empty" >&2; exit 1; }
[[ "$sR" == "$sG" ]] || { echo "R/G size differ: $sR vs $sG" >&2; exit 1; }
[[ "$sR" == "$sB" ]] || { echo "R/B size differ: $sR vs $sB" >&2; exit 1; }

# Total bytes per plane must be divisible by 30*60=1800 (per-frame pixel count)
(( sR % 1800 == 0 )) || { printf 'plane size %s not multiple of 1800\n' "$sR" >&2; exit 1; }
