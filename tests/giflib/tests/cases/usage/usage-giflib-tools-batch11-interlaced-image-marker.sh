#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-interlaced-image-marker
# @title: giftext interlaced image marker
# @description: Runs giftext on the interlaced fixture and checks image markers are emitted.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-interlaced-image-marker"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

giftext "$samples/treescap-interlaced.gif" | tee "$tmpdir/out"
grep -Eq 'Image #[0-9]+' "$tmpdir/out"
