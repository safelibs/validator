#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftext-treescap-image-record-count
# @title: giftext treescap.gif emits one Image record header per frame
# @description: Runs giftext on treescap.gif and asserts the count of "Image #" record headers equals the per-frame count reported by giftool -f '%n\n', confirming giftext enumerates one record per image descriptor.
# @timeout: 60
# @tags: usage, cli, giftext, image-record
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"

frames=$(wc -l <"$tmpdir/n.txt")
images=$(grep -cE '^Image #' "$tmpdir/info.txt" || true)

[[ "$frames" -ge 1 ]]
[[ "$images" -eq "$frames" ]] || {
    printf 'image record count=%s != frames=%s\n' "$images" "$frames" >&2
    exit 1
}
