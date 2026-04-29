#!/usr/bin/env bash
# @testcase: malformed-webp-rejection
# @title: Malformed WebP rejection
# @description: Requires dwebp to fail on bytes that are not WebP data.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'not webp\n' >"$tmpdir/bad.webp"; if dwebp "$tmpdir/bad.webp" -o "$tmpdir/out.ppm" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
