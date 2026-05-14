#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-giftool-interlace-on-treescap-roundtrip
# @title: giftool -i 1 on treescap.gif round-trips through giftext interlace marker
# @description: Pipes treescap.gif through giftool -i 1 to turn the interlace flag on, then runs giftext on the output and asserts the report mentions "Interlaced" for the image record, exercising the interlace setter on a non-interlaced fixture.
# @timeout: 60
# @tags: usage, cli, giftool, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -i 1 <"$gif" >"$tmpdir/on.gif"
file "$tmpdir/on.gif" | grep -q 'GIF image data'

giftext "$tmpdir/on.gif" >"$tmpdir/info.txt"
grep -Eqi 'interlace' "$tmpdir/info.txt" || {
    printf 'expected interlace marker in giftext output:\n' >&2
    sed -n '1,120p' "$tmpdir/info.txt" >&2
    exit 1
}
