#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-dump-lines
# @title: gifbuild fire dump lines
# @description: Dumps fire.gif with gifbuild and verifies the textual description contains content.
# @timeout: 180
# @tags: usage, gif, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-fire-dump-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
test "$(wc -l <"$tmpdir/dump.txt")" -gt 0
