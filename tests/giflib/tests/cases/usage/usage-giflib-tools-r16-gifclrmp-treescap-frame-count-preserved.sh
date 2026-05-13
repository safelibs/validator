#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-gifclrmp-treescap-frame-count-preserved
# @title: gifclrmp -s/-l round-trip on treescap.gif preserves the screen size token
# @description: Dumps treescap.gif's colormap via gifclrmp -s into a file, reloads the same palette via gifclrmp -l onto the original input, and asserts the rebuilt GIF reports the same screen size (giftool -f '%s\n', deduplicated) as the original, exercising the colormap-translation roundtrip at screen-geometry granularity.
# @timeout: 60
# @tags: usage, cli, gifclrmp, screen-size
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$tmpdir/palette.map" "$gif" >"$tmpdir/dump.gif"
validator_require_file "$tmpdir/palette.map"

gifclrmp -l "$tmpdir/palette.map" "$gif" >"$tmpdir/out.gif"
file "$tmpdir/out.gif" | grep -q 'GIF image data'

orig=$(giftool -f '%s\n' <"$gif" | sort -u)
rebuilt=$(giftool -f '%s\n' <"$tmpdir/out.gif" | sort -u)
[[ -n "$orig" ]]
[[ "$orig" == "$rebuilt" ]] || {
    printf 'screen size drift: orig=%s rebuilt=%s\n' "$orig" "$rebuilt" >&2
    exit 1
}
