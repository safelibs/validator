#!/usr/bin/env bash
# @testcase: usage-sed-capture-group
# @title: sed capture group replacement
# @description: Exercises sed capture group replacement through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-capture-group"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha-42\n' | sed -E 's/^([a-z]+)-([0-9]+)$/\2:\1/' >"$tmpdir/out"
grep -Fxq '42:alpha' "$tmpdir/out"
