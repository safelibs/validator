#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-grid-dump
# @title: gifbuild grid dump
# @description: Dumps gifgrid.gif with gifbuild and checks for image records in the text form.
# @timeout: 180
# @tags: usage, gif, metadata
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-grid-dump"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
grep -Ei 'screen|image' "$tmpdir/dump.txt" | tee "$tmpdir/out"
grep -Eiq 'screen|image' "$tmpdir/out"
