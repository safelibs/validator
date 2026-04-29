#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-interlace-flag
# @title: gifbuild interlace flag dump
# @description: Dumps plain and interlaced treescap fixtures with gifbuild and verifies only the interlaced dump reports the interlace flag.
# @timeout: 180
# @tags: usage, gif, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-interlace-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gifbuild -d "$samples/treescap.gif" >"$tmpdir/plain.txt"
gifbuild -d "$samples/treescap-interlaced.gif" >"$tmpdir/interlaced.txt"
if grep -Fq 'image interlaced' "$tmpdir/plain.txt"; then
  printf 'plain treescap dump unexpectedly reported interlacing\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/interlaced.txt" 'image interlaced'
