#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-fire-planar-equal-channels
# @title: gif2rgb fire equal planar channels
# @description: Converts the fire fixture to planar RGB and checks equal channel sizes.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-fire-planar-equal-channels"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gif2rgb -o "$tmpdir/fire" "$samples/fire.gif"
size_r=$(wc -c <"$tmpdir/fire.R")
size_g=$(wc -c <"$tmpdir/fire.G")
size_b=$(wc -c <"$tmpdir/fire.B")
test "$size_r" -gt 0
test "$size_r" -eq "$size_g"
test "$size_g" -eq "$size_b"
