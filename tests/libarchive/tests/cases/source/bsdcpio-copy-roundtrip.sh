#!/usr/bin/env bash
# @testcase: bsdcpio-copy-roundtrip
# @title: bsdcpio copy archive round trip
# @description: Copies files into and out of a newc archive using bsdcpio.
# @timeout: 120
# @tags: cli, archive

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"; printf 'cpio payload\n' >"$tmpdir/in/sub/payload.txt"; (cd "$tmpdir/in" && find . -print | sort | bsdcpio -o -H newc >"$tmpdir/a.cpio"); (cd "$tmpdir/out" && bsdcpio -id <"$tmpdir/a.cpio"); cmp "$tmpdir/in/sub/payload.txt" "$tmpdir/out/sub/payload.txt"; bsdcpio -it <"$tmpdir/a.cpio"
