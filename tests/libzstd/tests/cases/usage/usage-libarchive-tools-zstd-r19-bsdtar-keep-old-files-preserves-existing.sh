#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r19-bsdtar-keep-old-files-preserves-existing
# @title: bsdtar -x -k on tar.zst fails to overwrite an existing destination file
# @description: Creates a tar.zst archive carrying payload.txt, pre-populates the destination with a sentinel payload.txt, runs bsdtar -xkf on the archive, and asserts the pre-existing file is left untouched (its bytes unchanged) confirming the libarchive -k overwrite-refusal path with zstd.
# @timeout: 60
# @tags: usage, archive, bsdtar, zstd, keep-old, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
mkdir -p "$src"
printf 'archived content\n' >"$src/payload.txt"
(cd "$src" && bsdtar --zstd -cf "$tmpdir/archive.tar.zst" payload.txt)

dest="$tmpdir/dest"
mkdir -p "$dest"
printf 'pre-existing sentinel\n' >"$dest/payload.txt"
sentinel_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')

status=0
(cd "$dest" && bsdtar -xkf "$tmpdir/archive.tar.zst") >"$tmpdir/out.log" 2>"$tmpdir/err.log" || status=$?

# bsdtar -k must leave the pre-existing file untouched. The exit status is 0 on
# Ubuntu 24.04's libarchive and no error message is emitted; that is OK as long
# as the destination bytes match the sentinel SHA.
post_sha=$(sha256sum "$dest/payload.txt" | awk '{print $1}')
[[ "$post_sha" == "$sentinel_sha" ]] || {
    echo "expected pre-existing payload.txt to be preserved by bsdtar -k" >&2
    cat "$tmpdir/err.log" >&2
    exit 1
}
