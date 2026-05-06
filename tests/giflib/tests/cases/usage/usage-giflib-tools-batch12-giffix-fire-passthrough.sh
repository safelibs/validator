#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giffix-fire-passthrough
# @title: giffix produces a recognizable GIF from a clean source
# @description: Runs giffix on a non-interlaced fixture and verifies the output is a non-empty file that the file(1) magic database recognizes as GIF image data.
# @timeout: 60
# @tags: usage, cli, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giffix <"$gif" >"$tmpdir/fixed.gif"
[[ -s "$tmpdir/fixed.gif" ]]
file "$tmpdir/fixed.gif" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'GIF image data'
