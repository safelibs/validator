#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-gifclrmp-fire-dump-palette-count
# @title: gifclrmp -s on fire dumps 256-entry palette
# @description: Runs gifclrmp -s on the fire fixture and verifies the dumped palette has exactly 256 entries (one per color slot).
# @timeout: 60
# @tags: usage, cli, gifclrmp
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"
count=$(wc -l <"$tmpdir/palette.txt")
[[ "$count" == 256 ]]

# Each line should have three integers separated by whitespace
awk '{ if (NF < 3) exit 1 }' "$tmpdir/palette.txt"
