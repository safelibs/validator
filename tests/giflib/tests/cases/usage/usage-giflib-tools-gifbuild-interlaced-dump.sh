#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-interlaced-dump
# @title: gifbuild interlaced dump
# @description: Exercises gifbuild interlaced dump through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-interlaced-dump"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

gifbuild -d "$samples/treescap-interlaced.gif" >"$tmpdir/dump.txt"
grep -Eiq 'screen|image' "$tmpdir/dump.txt"
