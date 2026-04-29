#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-dump
# @title: gifbuild treescap dump
# @description: Dumps treescap.gif with gifbuild and checks for image records in the text form.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-treescap-dump"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
grep -Ei 'screen|image' "$tmpdir/dump.txt" | tee "$tmpdir/out"
grep -Eiq 'screen|image' "$tmpdir/out"
