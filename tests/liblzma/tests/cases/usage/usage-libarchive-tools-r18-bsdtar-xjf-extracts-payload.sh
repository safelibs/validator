#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-bsdtar-xjf-extracts-payload
# @title: bsdtar -xJf extracts a tar.xz member with byte-identical payload
# @description: Builds a tar.xz containing a known payload, extracts it with bsdtar -xJf into a fresh directory, and asserts the extracted file SHA matches the original — exercising the libarchive xz read pipeline end-to-end.
# @timeout: 60
# @tags: usage, bsdtar, xz, extract, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
python3 -c "import sys; sys.stdout.buffer.write(b'r18-extract-payload-' * 256)" >"$tmpdir/src/data.bin"
src_sha=$(sha256sum "$tmpdir/src/data.bin" | awk '{print $1}')

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" data.bin)
validator_require_file "$tmpdir/out.tar.xz"

mkdir "$tmpdir/dst"
(cd "$tmpdir/dst" && bsdtar -xJf "$tmpdir/out.tar.xz")
validator_require_file "$tmpdir/dst/data.bin"

dst_sha=$(sha256sum "$tmpdir/dst/data.bin" | awk '{print $1}')
[[ "$src_sha" == "$dst_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$dst_sha" >&2
  exit 1
}
