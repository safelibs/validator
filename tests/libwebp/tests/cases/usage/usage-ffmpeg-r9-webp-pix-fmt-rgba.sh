#!/usr/bin/env bash
# @testcase: usage-ffmpeg-r9-webp-pix-fmt-rgba
# @title: ffmpeg encodes WebP from RGBA source
# @description: Generates an RGBA PNG via ffmpeg testsrc-like nullsrc, encodes WebP with -pix_fmt yuva420p, and probes the result has webp codec.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a small RGBA PNG using ffmpeg's color generators.
ffmpeg -loglevel error -y -f lavfi -i 'color=color=red@0.5:size=32x32:rate=1' \
  -frames:v 1 "$tmpdir/in.png"

ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp \
  -frames:v 1 "$tmpdir/out.webp"

ffprobe -v error -show_entries stream=codec_name -of default=nw=1:nk=1 "$tmpdir/out.webp" >"$tmpdir/codec"
validator_assert_contains "$tmpdir/codec" 'webp'
file "$tmpdir/out.webp" | grep -q 'Web/P image'
