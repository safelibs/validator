#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-gifbuild-fire-roundtrip-screen-size
# @title: gifbuild dump-then-build preserves fire.gif logical screen size
# @description: Dumps fire.gif via gifbuild -d, rebuilds it via gifbuild, and asserts the rebuilt GIF reports the same logical screen size (giftool -f '%s\n', deduplicated) as the original, exercising the parse-then-rebuild path at screen-geometry granularity.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"

file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'

orig=$(giftool -f '%s\n' <"$gif" | sort -u)
rebuilt=$(giftool -f '%s\n' <"$tmpdir/rebuilt.gif" | sort -u)
[[ -n "$orig" ]]
[[ "$orig" == "$rebuilt" ]] || {
    printf 'screen size drift: orig=%s rebuilt=%s\n' "$orig" "$rebuilt" >&2
    exit 1
}
