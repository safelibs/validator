#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-gifbuild-treescap-roundtrip-byte-equal
# @title: gifbuild treescap dump-then-build is byte-stable on second pass
# @description: Dumps treescap GIF with gifbuild -d, builds it back, dumps and rebuilds again, and confirms two consecutive rebuilt GIFs are byte identical.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump1.txt"
gifbuild "$tmpdir/dump1.txt" >"$tmpdir/build1.gif"

gifbuild -d "$tmpdir/build1.gif" >"$tmpdir/dump2.txt"
gifbuild "$tmpdir/dump2.txt" >"$tmpdir/build2.gif"

cmp "$tmpdir/build1.gif" "$tmpdir/build2.gif"
