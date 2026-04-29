#!/usr/bin/env bash
# @testcase: usage-vips-stats-jpeg
# @title: vips stats jpeg
# @description: Runs vips stats on a JPEG fixture through libjpeg-turbo.
# @timeout: 180
# @tags: usage, image, cli
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1], 'wb').write(b'P6\n4 3\n255\n' + bytes([255,0,0,0,255,0,0,0,255,255,255,0,255,0,255,0,255,255,40,40,40,220,220,220,100,20,30,20,100,30,20,30,100,200,120,20]))
PY
    cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"
    vips stats "$tmpdir/in.jpg" "$tmpdir/stats.v"
vipsheader "$tmpdir/stats.v"
