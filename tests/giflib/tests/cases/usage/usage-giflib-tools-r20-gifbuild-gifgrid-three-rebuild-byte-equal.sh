#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-gifbuild-gifgrid-three-rebuild-byte-equal
# @title: gifbuild dump/rebuild on gifgrid.gif converges to a fixed point after the first rebuild
# @description: Pipes gifgrid.gif through two successive gifbuild dump-rebuild cycles and asserts the second and third rebuilt GIF files are byte-for-byte identical, exercising convergence of the dump-and-rebuild round-trip after the first canonicalisation pass on the gifgrid fixture distinct from prior double-roundtrip tests on fire/treescap.
# @timeout: 60
# @tags: usage, cli, gifbuild, idempotent, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/d1.txt"
gifbuild "$tmpdir/d1.txt" >"$tmpdir/r1.gif"
gifbuild -d "$tmpdir/r1.gif" >"$tmpdir/d2.txt"
gifbuild "$tmpdir/d2.txt" >"$tmpdir/r2.gif"
gifbuild -d "$tmpdir/r2.gif" >"$tmpdir/d3.txt"
gifbuild "$tmpdir/d3.txt" >"$tmpdir/r3.gif"

cmp "$tmpdir/r2.gif" "$tmpdir/r3.gif"
