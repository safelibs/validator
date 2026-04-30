#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-batch12-no-same-permissions
# @title: bsdtar zstd -p preserves a non-default file mode
# @description: Archives a 0644 file into a zstd-compressed tar, extracts it with bsdtar -p (--same-permissions) under a restrictive umask, and verifies the explicit mode bits stored in the archive override the umask so the extracted file matches the saved 0644 mode rather than being clamped down to the umask-implied default.
# @timeout: 180
# @tags: usage, archive, zstd, metadata
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Restrictive umask so -p has visible effect on extraction (without -p the
# extracted mode would be clamped to ~0077 against the stored 0644).
umask 0077

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'plain payload\n' >"$tmpdir/in/plain.dat"
chmod 0644 "$tmpdir/in/plain.dat"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" plain.dat
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# -p tells bsdtar to honour the archived permission bits exactly, ignoring
# the current umask.
bsdtar -p -xf "$tmpdir/a.tar.zst" -C "$tmpdir/out"

mode=$(stat -c %a "$tmpdir/out/plain.dat")
# With -p the extracted mode must equal the saved 0644 bits even though
# the umask would otherwise have stripped group/other read.
test "$mode" = "644" || {
  printf 'expected mode 644 with -p, got %s\n' "$mode" >&2
  exit 1
}
