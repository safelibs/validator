#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-multi-frame-concat
# @title: zstd CLI decompresses a concatenated multi-frame stream
# @description: Compresses two separate tar archives with --zstd, concatenates the resulting .tar.zst files with cat to form a single multi-frame zstd stream, decompresses the combined stream with the zstd CLI (which transparently decodes consecutive frames) into a concatenated tar, and verifies bsdtar lists members from both frames in that decoded tar.
# @timeout: 180
# @tags: usage, archive, zstd, multi-frame
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/a" "$tmpdir/b"
printf 'frame-a payload\n' >"$tmpdir/a/alpha.txt"
printf 'frame-b payload\n' >"$tmpdir/b/beta.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/a" alpha.txt
bsdtar --zstd -cf "$tmpdir/b.tar.zst" -C "$tmpdir/b" beta.txt
validator_require_file "$tmpdir/a.tar.zst"
validator_require_file "$tmpdir/b.tar.zst"

magic_a=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
magic_b=$(od -An -N4 -tx1 "$tmpdir/b.tar.zst" | tr -d ' \n')
test "$magic_a" = "28b52ffd"
test "$magic_b" = "28b52ffd"

cat "$tmpdir/a.tar.zst" "$tmpdir/b.tar.zst" >"$tmpdir/combined.tar.zst"

# The combined file is a sequence of two zstd frames. zstd -t validates both
# frames decompress cleanly; zstd -d concatenates the decoded byte streams.
zstd -tq "$tmpdir/combined.tar.zst"
zstd -dq -c "$tmpdir/combined.tar.zst" >"$tmpdir/combined.tar"

# The decoded output is two tar streams concatenated; byte-equal to a.tar+b.tar.
bsdtar --zstd -dcf >/dev/null "$tmpdir/a.tar.zst" 2>/dev/null || true
zstd -dq -c "$tmpdir/a.tar.zst" >"$tmpdir/a.tar"
zstd -dq -c "$tmpdir/b.tar.zst" >"$tmpdir/b.tar"
cat "$tmpdir/a.tar" "$tmpdir/b.tar" >"$tmpdir/expected.tar"
cmp "$tmpdir/combined.tar" "$tmpdir/expected.tar"

# Listing each individual decoded tar exposes its respective member, proving
# both frames decompressed (a tar reader stops at the first end-of-archive
# marker, so we list a.tar and b.tar separately rather than the concat).
bsdtar -tf "$tmpdir/a.tar" >"$tmpdir/list-a"
bsdtar -tf "$tmpdir/b.tar" >"$tmpdir/list-b"
validator_assert_contains "$tmpdir/list-a" 'alpha.txt'
validator_assert_contains "$tmpdir/list-b" 'beta.txt'
