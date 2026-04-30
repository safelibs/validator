#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-screen-size-line
# @title: gifbuild dump records fire screen dimensions
# @description: Dumps fire.gif with gifbuild -d and verifies the screen width and height keywords in the textual description match the known 30x60 logical screen of the fixture.
# @timeout: 60
# @tags: usage, cli, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Sanity: fire.gif is the canonical 30x60 fixture this test expects.
file "$gif" | grep -q '30 x 60'

gifbuild -d "$gif" >"$tmpdir/dump.txt"

validator_assert_contains "$tmpdir/dump.txt" 'screen width 30'
validator_assert_contains "$tmpdir/dump.txt" 'screen height 60'
