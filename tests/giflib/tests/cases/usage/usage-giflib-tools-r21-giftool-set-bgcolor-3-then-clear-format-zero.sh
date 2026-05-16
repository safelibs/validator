#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-giftool-set-bgcolor-3-then-clear-format-zero
# @title: giftool -b 3 then -b 0 on treescap.gif yields background index 0 in giftool -f %b
# @description: Chains two giftool -b invocations against treescap.gif (first sets background to 3, then resets to 0) and asserts giftool -f %b reports 0 for every frame in the final output, exercising the background-index setter override behavior distinct from prior single-setter-only background tests.
# @timeout: 60
# @tags: usage, cli, giftool, background, chain, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -b 3 <"$gif" >"$tmpdir/step1.gif"
giftool -b 0 <"$tmpdir/step1.gif" >"$tmpdir/step2.gif"

giftool -f '%b\n' <"$tmpdir/step2.gif" >"$tmpdir/b.txt"
unique=$(sort -u "$tmpdir/b.txt")
[[ "$unique" == "0" ]] || { echo "unexpected backgrounds: $unique" >&2; exit 1; }
