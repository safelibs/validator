#!/usr/bin/env bash
# @testcase: malformed-jpeg-handling
# @title: Malformed JPEG input handling
# @description: Requires djpeg to return failure for non-JPEG input bytes.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'not jpeg\n' >"$tmpdir/bad.jpg"; if djpeg "$tmpdir/bad.jpg" >"$tmpdir/out" 2>"$tmpdir/log"; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
