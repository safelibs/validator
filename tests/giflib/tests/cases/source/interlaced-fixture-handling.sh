#!/usr/bin/env bash
# @testcase: interlaced-fixture-handling
# @title: Interlaced GIF fixture handling
# @description: Converts an interlaced GIF fixture and compares the expected RGB output.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"; expected="$VALIDATOR_SAMPLE_ROOT/tests/treescap-interlaced.rgb"; validator_require_file "$gif"; validator_require_file "$expected"; gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"; cmp "$expected" "$tmpdir/out.rgb"
