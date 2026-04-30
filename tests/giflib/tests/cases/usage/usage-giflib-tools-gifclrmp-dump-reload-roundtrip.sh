#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-dump-reload-roundtrip
# @title: gifclrmp dump and -l reload roundtrip
# @description: Dumps the global color map with gifclrmp, reloads it via gifclrmp -l, and confirms the dumped map is identical after the round trip.
# @timeout: 60
# @tags: usage, cli, gifclrmp, colormap
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/cmap.txt"
[[ "$(wc -l <"$tmpdir/cmap.txt")" -eq 16 ]]

gifclrmp -l "$tmpdir/cmap.txt" "$gif" >"$tmpdir/roundtrip.gif"
file "$tmpdir/roundtrip.gif" | grep -q 'GIF image data'

gifclrmp -s "$tmpdir/roundtrip.gif" >"$tmpdir/cmap2.txt"
cmp "$tmpdir/cmap.txt" "$tmpdir/cmap2.txt"
