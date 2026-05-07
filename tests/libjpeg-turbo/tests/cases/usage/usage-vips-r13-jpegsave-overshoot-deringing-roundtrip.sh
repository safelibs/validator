#!/usr/bin/env bash
# @testcase: usage-vips-r13-jpegsave-overshoot-deringing-roundtrip
# @title: vips jpegsave --overshoot-deringing produces a valid JPEG at the original size
# @description: Saves a JPEG via vips jpegsave with --overshoot-deringing (a mozjpeg-style ringing-mitigation flag) and confirms the output is a syntactically valid JPEG that vipsheader reloads at the input geometry.
# @timeout: 60
# @tags: usage, jpeg, image, mozjpeg
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 56, 40
data = bytes([(((x * 9) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/od.jpg" --overshoot-deringing --Q 80

file "$tmpdir/od.jpg" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader -a "$tmpdir/od.jpg" >"$tmpdir/hdr"
validator_assert_contains "$tmpdir/hdr" 'width: 56'
validator_assert_contains "$tmpdir/hdr" 'height: 40'
