#!/usr/bin/env bash
# @testcase: malformed-tiff-rejection
# @title: Malformed TIFF rejection
# @description: Requires tiffinfo to fail on bytes that are not a TIFF file.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'not tiff\n' >"$tmpdir/bad.tiff"; if tiffinfo "$tmpdir/bad.tiff" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
