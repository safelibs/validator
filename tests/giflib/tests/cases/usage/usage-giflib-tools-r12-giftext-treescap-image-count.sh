#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftext-treescap-image-count
# @title: giftext on treescap.gif reports the same image count as giftool
# @description: Counts "Image" header sections in giftext output for treescap.gif and asserts the count equals the per-frame line count from giftool -f '%n\n', cross-checking the two readers agree on frame count.
# @timeout: 60
# @tags: usage, cli, giftext, cross-check
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.out"
giftool -f '%n\n' <"$gif" >"$tmpdir/idx.txt"

# giftext emits a section for every image; count distinct "Image #" headers.
text_images=$(grep -cE '^Image #[0-9]+:' "$tmpdir/text.out" || true)
tool_images=$(wc -l <"$tmpdir/idx.txt")

[[ "$tool_images" -ge 1 ]]
[[ "$text_images" -ge 1 ]]
[[ "$text_images" == "$tool_images" ]]
