#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-giftool-disposal-two-fire-gifbuild-dump
# @title: giftool -x 2 on fire.gif yields gifbuild dump lines with "disposal mode 2"
# @description: Pipes fire.gif through giftool -x 2 to set the disposal field on each frame to 2 (restore-to-background), then runs gifbuild -d and asserts the dump contains at least one "disposal mode 2" line, exercising the disposal setter through the gifbuild text dump.
# @timeout: 60
# @tags: usage, cli, giftool, disposal, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -x 2 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/d.gif" >"$tmpdir/dump.txt"
grep -q 'disposal mode 2' "$tmpdir/dump.txt" || {
    printf 'expected disposal mode 2 line in dump:\n' >&2
    sed -n '1,80p' "$tmpdir/dump.txt" >&2
    exit 1
}
