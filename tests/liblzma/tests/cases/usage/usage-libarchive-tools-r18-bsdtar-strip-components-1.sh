#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-bsdtar-strip-components-1
# @title: bsdtar -xJf --strip-components 1 flattens a single leading directory from a tar.xz
# @description: Builds a tar.xz containing one nested file under a single top-level directory, extracts it with bsdtar -xJf --strip-components 1, and asserts the file lands without the leading directory prefix — exercising the libarchive path-component stripping path on xz inputs.
# @timeout: 60
# @tags: usage, bsdtar, xz, strip-components, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/topdir"
printf 'r18-strip-payload\n' >"$tmpdir/src/topdir/inner.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" topdir/inner.txt)

mkdir "$tmpdir/dst"
(cd "$tmpdir/dst" && bsdtar -xJf "$tmpdir/out.tar.xz" --strip-components 1)

test -f "$tmpdir/dst/inner.txt" \
  || { printf 'expected stripped inner.txt at extraction root\n' >&2; exit 1; }
test ! -e "$tmpdir/dst/topdir" \
  || { printf 'leading topdir/ should be stripped\n' >&2; exit 1; }
