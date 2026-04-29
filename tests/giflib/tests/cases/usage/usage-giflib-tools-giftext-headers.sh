#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-headers
# @title: giflib-tools giftext headers
# @description: Runs giflib-tools giftext headers on a GIF fixture and checks image metadata.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
giftext "$gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
