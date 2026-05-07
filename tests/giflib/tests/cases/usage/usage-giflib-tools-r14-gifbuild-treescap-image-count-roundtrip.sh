#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-gifbuild-treescap-image-count-roundtrip
# @title: gifbuild dump-then-build preserves treescap.gif image count
# @description: Dumps treescap.gif via gifbuild -d, rebuilds it via gifbuild, and verifies giftool -f '%n\n' reports the same per-frame count for the rebuilt GIF as for the original, exercising the parse-then-rebuild path at frame-count granularity.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"

file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'

orig=$(giftool -f '%n\n' <"$gif" | wc -l)
roundtrip=$(giftool -f '%n\n' <"$tmpdir/rebuilt.gif" | wc -l)

[[ "$orig" -ge 1 ]]
[[ "$orig" -eq "$roundtrip" ]] || {
    printf 'frame count drift: orig=%s roundtrip=%s\n' "$orig" "$roundtrip" >&2
    exit 1
}
