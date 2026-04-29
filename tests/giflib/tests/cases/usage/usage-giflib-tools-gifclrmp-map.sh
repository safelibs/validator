#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-map
# @title: giflib-tools gifclrmp map
# @description: Runs giflib-tools gifclrmp map on a GIF fixture and checks image metadata.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifclrmp "$gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
