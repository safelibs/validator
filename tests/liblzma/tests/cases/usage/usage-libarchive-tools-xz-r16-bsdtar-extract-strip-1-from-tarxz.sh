#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-bsdtar-extract-strip-1-from-tarxz
# @title: bsdtar -xJf with --strip-components 1 removes the top-level directory
# @description: Packs a top-level directory containing one file into a tar.xz, then extracts with bsdtar -xJf --strip-components 1 into an empty directory, and asserts the inner file appears at the extraction root (not under the original top-level prefix).
# @timeout: 120
# @tags: usage, bsdtar, xz, strip-components
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/top"
printf 'inner\n' >"$tmpdir/src/top/inner.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" top)

mkdir -p "$tmpdir/extract"
(cd "$tmpdir/extract" && bsdtar -xJf "$tmpdir/out.tar.xz" --strip-components 1)

test -f "$tmpdir/extract/inner.txt"
test ! -d "$tmpdir/extract/top"
grep -q '^inner$' "$tmpdir/extract/inner.txt"
