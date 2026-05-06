#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-set-userinput-flag-on
# @title: giftool -u 1 sets the GCB user-input flag on every frame
# @description: Pipes fire.gif through giftool -u 1 to enable the graphics control extension user-input flag, then re-reads the flag through giftool -f '%u\n' and confirms every frame now reports 1, exercising the user-input mutation path.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -u 1 <"$gif" >"$tmpdir/userset.gif"
file "$tmpdir/userset.gif" | grep -q 'GIF image data'

giftool -f '%u\n' <"$tmpdir/userset.gif" >"$tmpdir/u.txt"
unique=$(sort -u "$tmpdir/u.txt")
if [[ "$unique" != "1" ]]; then
    printf 'expected uniform user-input flag 1, got:\n' >&2
    sed -n '1,10p' "$tmpdir/u.txt" >&2
    exit 1
fi

# Cross-check via gifbuild dump: "user input flag on" line present.
gifbuild -d "$tmpdir/userset.gif" >"$tmpdir/dump.txt"
grep -qE '^[[:space:]]*user input flag on$' "$tmpdir/dump.txt"
