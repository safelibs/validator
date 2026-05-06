#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r9-webp-quality-five-vs-eighty
# @title: ffmpeg WebP low quality is smaller than high quality
# @description: Encodes the same source PNG twice with libwebp -q 5 and -q 95 and asserts the higher-quality file is larger than the lower-quality one.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ffmpeg -loglevel error -y -f lavfi -i 'mandelbrot=size=128x128:rate=1' \
  -frames:v 1 "$tmpdir/in.png"

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 5 -frames:v 1 "$tmpdir/lo.webp"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -quality 95 -frames:v 1 "$tmpdir/hi.webp"

lo=$(stat -c '%s' "$tmpdir/lo.webp")
hi=$(stat -c '%s' "$tmpdir/hi.webp")
[[ "$hi" -gt "$lo" ]] || { echo "expected hi>lo, got hi=$hi lo=$lo" >&2; exit 1; }
file "$tmpdir/lo.webp" | grep -q 'Web/P'
file "$tmpdir/hi.webp" | grep -q 'Web/P'
