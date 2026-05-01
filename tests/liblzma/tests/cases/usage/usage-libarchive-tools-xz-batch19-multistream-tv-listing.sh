#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch19-multistream-tv-listing
# @title: bsdtar -tvJf reads multi-stream xz
# @description: Concatenates two independent .xz streams of a single tarball into a multi-stream xz file and confirms bsdtar -tvJf prints all member rows by walking each stream through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, multistream
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src1" "$tmpdir/src2"
printf 'first stream payload\n' >"$tmpdir/src1/one.txt"
printf 'second stream payload\n' >"$tmpdir/src2/two.txt"

# Create one tar per source tree, then xz each tar to its own .xz stream.
bsdtar -cf "$tmpdir/one.tar" -C "$tmpdir/src1" one.txt
bsdtar -cf "$tmpdir/two.tar" -C "$tmpdir/src2" two.txt
xz -z -c "$tmpdir/one.tar" >"$tmpdir/one.tar.xz"
xz -z -c "$tmpdir/two.tar" >"$tmpdir/two.tar.xz"

# Concatenated .xz forms a valid multi-stream xz file per the .xz spec.
cat "$tmpdir/one.tar.xz" "$tmpdir/two.tar.xz" >"$tmpdir/multi.tar.xz"

# .xz magic still present at offset 0
magic_hex=$(head -c 6 "$tmpdir/multi.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# xz --list reports two streams
xz --list "$tmpdir/multi.tar.xz" >"$tmpdir/xzlist.txt"
streams_line=$(grep -E 'totals' "$tmpdir/xzlist.txt" || true)
# Fallback: count summary lines reporting 2 streams via xz --robot
xz --robot --list "$tmpdir/multi.tar.xz" >"$tmpdir/xzrobot.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/xzrobot.txt")
test "$totals_streams" = "2"

# bsdtar must read members from both streams (use --ignore-zeros so the
# zero-block end-of-archive marker between the two inner tars does not stop
# the listing).
bsdtar --ignore-zeros -tvJf "$tmpdir/multi.tar.xz" >"$tmpdir/list.txt"
test "$(wc -l <"$tmpdir/list.txt")" -eq 2
grep -Eq ' one\.txt$' "$tmpdir/list.txt"
grep -Eq ' two\.txt$' "$tmpdir/list.txt"
