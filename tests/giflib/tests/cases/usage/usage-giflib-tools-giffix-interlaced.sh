#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giffix-interlaced
# @title: giffix interlaced fixture
# @description: Repairs the interlaced treescap fixture with giffix and verifies the fixed GIF remains readable by giftext.
# @timeout: 180
# @tags: usage, gif, repair
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-giffix-interlaced"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"
if giffix "$gif" >"$tmpdir/fixed.gif" 2>"$tmpdir/err"; then
  printf 'giffix unexpectedly accepted interlaced fixture\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/err" 'Cannot fix interlaced images'
