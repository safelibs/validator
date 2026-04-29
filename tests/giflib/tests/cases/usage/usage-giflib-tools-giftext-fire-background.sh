#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-background
# @title: giftext fire background field
# @description: Exercises giftext fire background field through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giftext-fire-background"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

giftext "$samples/fire.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'BackGround'
