#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-gif2rgb-treescap-stream-byte-multiple
# @title: gif2rgb -1 stream output is divisible by 3 for treescap.gif
# @description: Decodes treescap.gif via gif2rgb -1 into a single concatenated RGB byte stream and confirms the byte count is a positive multiple of 3 (one byte per channel triplet).
# @timeout: 60
# @tags: usage, cli, gif2rgb, stream
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/treescap.rgb" "$gif"
[[ -s "$tmpdir/treescap.rgb" ]]

bytes=$(wc -c <"$tmpdir/treescap.rgb")
[[ "$bytes" -gt 0 ]]
[[ $((bytes % 3)) -eq 0 ]] || {
    printf 'rgb stream byte count %s is not a multiple of 3\n' "$bytes" >&2
    exit 1
}
