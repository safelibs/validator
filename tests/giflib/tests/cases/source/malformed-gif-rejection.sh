#!/usr/bin/env bash
# @testcase: malformed-gif-rejection
# @title: Malformed GIF rejection
# @description: Confirms truncated GIF input is rejected by an installed giflib tool.
# @timeout: 120
# @tags: cli, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"; validator_require_file "$gif"; head -c 32 "$gif" >"$tmpdir/bad.gif"; if giftext "$tmpdir/bad.gif" >"$tmpdir/log" 2>&1; then cat "$tmpdir/log"; exit 1; fi; cat "$tmpdir/log"
