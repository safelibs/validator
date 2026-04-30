#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch12-gnu-tar-interop
# @title: bsdtar reads tar produced by xz pipe
# @description: Builds a tarball with GNU tar piped through xz then extracts with bsdtar to confirm liblzma decompresses the GNU-produced stream.
# @timeout: 180
# @tags: usage, archive, xz, interop
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/dir" "$tmpdir/out"
printf 'gnu interop alpha\n' >"$tmpdir/in/alpha.txt"
printf 'gnu interop beta\n' >"$tmpdir/in/dir/beta.txt"

# Produce the archive with the canonical Linux tar piped through xz(1)
tar -cf - -C "$tmpdir/in" . | xz -z -c >"$tmpdir/a.tar.xz"

# Confirm .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdtar (libarchive + liblzma) must accept the GNU-produced stream
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/in/dir/beta.txt" "$tmpdir/out/dir/beta.txt"

# sha256 of source vs extracted must match
sha_in=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_out=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
test "$sha_in" = "$sha_out"
