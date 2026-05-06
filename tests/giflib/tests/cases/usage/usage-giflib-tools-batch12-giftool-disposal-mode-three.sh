#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giftool-disposal-mode-three
# @title: giftool -x 3 sets disposal mode to restore-previous
# @description: Applies giftool -x 3 (restore-previous disposal mode) to fire.gif and verifies gifbuild dump shows "disposal mode 3" on every graphics control extension.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -x 3 <"$gif" >"$tmpdir/disp.gif"
file "$tmpdir/disp.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/disp.gif" >"$tmpdir/dump.txt"
count=$(grep -cE '^[[:space:]]+disposal mode 3$' "$tmpdir/dump.txt")
[[ "$count" -ge 1 ]]

# Confirm no other disposal mode appears for the disposal mode line.
other=$(grep -cE '^[[:space:]]+disposal mode [^3]$' "$tmpdir/dump.txt" || true)
[[ "$other" == 0 ]]
