#!/usr/bin/env bash
# @testcase: gifbuild-roundtrip
# @title: gifbuild textual round trip
# @description: Dumps a GIF to textual form and rebuilds an equivalent GIF stream.
# @timeout: 120
# @tags: cli, roundtrip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"; validator_require_file "$gif"; gifbuild -d "$gif" >"$tmpdir/spec.txt"; gifbuild "$tmpdir/spec.txt" >"$tmpdir/rebuilt.gif"; giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/rebuilt.txt"; grep -Ei 'screen|image|gif' "$tmpdir/rebuilt.txt" >/dev/null
