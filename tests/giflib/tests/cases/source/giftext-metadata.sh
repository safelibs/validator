#!/usr/bin/env bash
# @testcase: giftext-metadata
# @title: giftext metadata inspection
# @description: Inspects GIF metadata from an upstream sample with the giftext tool.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"; validator_require_file "$gif"; giftext "$gif" | tee "$tmpdir/out.txt"; grep -Ei 'screen|image|gif' "$tmpdir/out.txt" >/dev/null
