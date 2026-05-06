#!/usr/bin/env bash
# @testcase: usage-ffprobe-r10-webp-of-csv-streams
# @title: ffprobe -of csv reports webp codec on a WebP stream
# @description: Encodes a WebP via ffmpeg then runs ffprobe with -of csv -show_streams and asserts a webp codec name appears in the CSV output.
# @timeout: 180
# @tags: usage, ffmpeg, webp
# @client: ffmpeg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ffmpeg -loglevel error -y -f lavfi -i 'color=color=blue:size=48x48:duration=1:rate=1' \
       -frames:v 1 "$tmpdir/in.png"
ffmpeg -loglevel error -y -i "$tmpdir/in.png" -c:v libwebp -frames:v 1 "$tmpdir/out.webp"

ffprobe -v error -of csv -show_streams "$tmpdir/out.webp" >"$tmpdir/streams.csv"
[[ -s "$tmpdir/streams.csv" ]]
grep -q 'webp' "$tmpdir/streams.csv"
