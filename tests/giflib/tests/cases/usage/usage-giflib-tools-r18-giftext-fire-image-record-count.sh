#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-giftext-fire-image-record-count
# @title: giftext on fire.gif emits at least as many Image lines as giftool reports frames
# @description: Runs giftext on fire.gif and counts lines containing the literal substring "Image ", then compares against the giftool -f '%n\n' frame count and asserts the giftext image-record count is greater than or equal to the frame count, exercising the per-image section emission on a multi-frame fixture.
# @timeout: 60
# @tags: usage, cli, giftext, image-record, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
frames=$(giftool -f '%n\n' <"$gif" | wc -l)
image_count=$(grep -c 'Image ' "$tmpdir/info.txt" || true)
(( frames > 0 ))
if (( image_count < frames )); then
    printf 'expected at least %s Image records, got %s\n' "$frames" "$image_count" >&2
    sed -n '1,80p' "$tmpdir/info.txt" >&2
    exit 1
fi
