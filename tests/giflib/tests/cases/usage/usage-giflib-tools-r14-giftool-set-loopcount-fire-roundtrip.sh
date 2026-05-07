#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftool-set-loopcount-fire-roundtrip
# @title: giftool fed its own output preserves fire.gif image and screen geometry
# @description: Pipes fire.gif through giftool with no flags (a no-op copy) and verifies the output is a structurally valid GIF whose per-frame count, screen size, and per-frame width/height (as reported by giftool -f) all match the input fixture.
# @timeout: 60
# @tags: usage, cli, giftool, identity
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool <"$gif" >"$tmpdir/copy.gif"
file "$tmpdir/copy.gif" | grep -q 'GIF image data'

# Per-frame count must match.
in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/copy.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}

# Screen size must match (single value).
in_s=$(giftool -f '%s\n' <"$gif" | sort -u)
out_s=$(giftool -f '%s\n' <"$tmpdir/copy.gif" | sort -u)
[[ "$in_s" == "$out_s" ]] || {
    printf 'screen size differs in=%s out=%s\n' "$in_s" "$out_s" >&2
    exit 1
}

# Per-frame width/height must match.
in_wh=$(giftool -f '%w %h\n' <"$gif" | sort -u)
out_wh=$(giftool -f '%w %h\n' <"$tmpdir/copy.gif" | sort -u)
[[ "$in_wh" == "$out_wh" ]] || {
    printf 'wh differs in=%s out=%s\n' "$in_wh" "$out_wh" >&2
    exit 1
}
