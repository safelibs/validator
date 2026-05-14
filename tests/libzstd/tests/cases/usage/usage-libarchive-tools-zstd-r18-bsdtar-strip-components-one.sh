#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r18-bsdtar-strip-components-one
# @title: bsdtar -x --strip-components 1 drops the leading path segment on tar.zst extraction
# @description: Creates a tar.zst archive containing a top/leaf.txt path layout, extracts it with bsdtar --strip-components 1 into a fresh directory, and asserts the extracted layout drops the leading 'top/' segment so leaf.txt appears at the destination root.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, strip-components, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src/top"
mkdir -p "$src"
printf 'r18 strip-components payload\n' >"$src/leaf.txt"

(cd "$tmpdir/src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" top)
validator_require_file "$tmpdir/archive.tar.zst"

dest="$tmpdir/dest"
mkdir -p "$dest"
(cd "$dest" && bsdtar --strip-components 1 -xf "$tmpdir/archive.tar.zst")

validator_require_file "$dest/leaf.txt"
[[ ! -e "$dest/top" ]] || { echo "expected 'top' prefix stripped" >&2; exit 1; }
grep -Fq 'r18 strip-components payload' "$dest/leaf.txt"
