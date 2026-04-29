#!/usr/bin/env bash
# @testcase: malformed-png-rejection
# @title: Malformed PNG rejection
# @description: Requires pngfix to reject bytes that are not a valid PNG file.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'not png\n' >"$tmpdir/bad.png"; if pngfix --out="$tmpdir/out.png" "$tmpdir/bad.png" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
