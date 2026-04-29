#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-grid-colormap
# @title: giffix grid color map
# @description: Runs giffix on gifgrid.gif and verifies the repaired stream still exposes palette data.
# @timeout: 180
# @tags: usage, gif, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-grid-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
giffix "$gif" >"$tmpdir/fixed.gif"
gifclrmp "$tmpdir/fixed.gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
