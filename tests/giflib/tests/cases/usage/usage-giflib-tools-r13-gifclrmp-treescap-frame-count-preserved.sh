#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-gifclrmp-treescap-frame-count-preserved
# @title: gifclrmp -l with the original palette preserves treescap frame count
# @description: Dumps treescap.gif's palette with gifclrmp -s, reloads the same palette via gifclrmp -l, and verifies the per-frame count reported by giftool -f '%n\n' is unchanged from the input fixture, exercising the colormap-translation pipeline at frame-count granularity.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Dump the palette and reload it via -l.
gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
[[ -s "$tmpdir/cmap.txt" ]]

gifclrmp -l "$tmpdir/cmap.txt" "$gif" >"$tmpdir/mapped.gif"
file "$tmpdir/mapped.gif" | grep -q 'GIF image data'

in_frames=$(giftool -f '%n\n' <"$gif" | wc -l)
out_frames=$(giftool -f '%n\n' <"$tmpdir/mapped.gif" | wc -l)

[[ "$in_frames" -ge 1 ]]
[[ "$in_frames" -eq "$out_frames" ]] || {
    printf 'frame count changed: in=%s out=%s\n' "$in_frames" "$out_frames" >&2
    exit 1
}
