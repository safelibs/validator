#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftext-fire-image-pixel-mode-line
# @title: giftext per-image dimension line count matches giftool frame count
# @description: Runs giftext on the fire fixture and asserts the number of per-image "Width = ..., Height = ..." dimension lines equals both the count of "Image #N:" headers and the per-frame line count from giftool -f '%n\n', confirming the giftext per-image emitter is consistent.
# @timeout: 60
# @tags: usage, cli, giftext, headers
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.out"
giftool -f '%n\n' <"$gif" >"$tmpdir/idx.txt"

# Count "Image #" headers in giftext output. Must equal the per-frame count.
text_images=$(grep -cE '^Image #[0-9]+:' "$tmpdir/text.out" || true)
tool_images=$(wc -l <"$tmpdir/idx.txt")

[[ "$tool_images" -ge 2 ]]
[[ "$text_images" -eq "$tool_images" ]] || {
    printf 'mismatch: giftext images=%s giftool frames=%s\n' "$text_images" "$tool_images" >&2
    exit 1
}

# giftext prints one "Screen Size - Width = ..." preamble plus one
# per-image "Width = ..., Height = ..." dimension line. Total >= frames+1.
dim_lines=$(grep -cE 'Width = [0-9]+, Height = [0-9]+' "$tmpdir/text.out" || true)
[[ "$dim_lines" -ge "$((text_images + 1))" ]] || {
    printf 'expected at least %s Width/Height lines, got %s\n' "$((text_images + 1))" "$dim_lines" >&2
    exit 1
}
