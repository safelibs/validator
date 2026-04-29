#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-grid
# @title: gifclrmp grid palette
# @description: Prints the gifgrid.gif color map with gifclrmp and checks indexed RGB rows.
# @timeout: 180
# @tags: usage, gif, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifclrmp-grid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gifclrmp "$gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
