#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-interlace-flag-on-then-format
# @title: giftool -i on sets per-frame interlace flag readable in gifbuild dump
# @description: Pipes fire.gif through giftool -i on to enable per-frame interlace, and verifies a gifbuild -d dump of the result reports an "interlaced on" line at least once and contains no "interlaced off" lines.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -i on <"$gif" >"$tmpdir/inter.gif"
file "$tmpdir/inter.gif" | grep -q 'GIF image data'

gifbuild -d "$tmpdir/inter.gif" >"$tmpdir/dump.txt"

on_count=$(grep -cE '^[[:space:]]*interlaced on$' "$tmpdir/dump.txt" || true)
off_count=$(grep -cE '^[[:space:]]*interlaced off$' "$tmpdir/dump.txt" || true)

[[ "$on_count" -ge 1 ]]
[[ "$off_count" -eq 0 ]]
