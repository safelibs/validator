#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-gnu-tar-cjf-interop
# @title: bsdtar reads tar.xz built by GNU tar -cJf
# @description: GNU tar invokes its xz auto-compressor via -J to build the archive directly (no pipe); bsdtar then extracts via liblzma and round-trip checksums must match.
# @timeout: 180
# @tags: usage, archive, xz, interop
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'gnu cJf alpha payload\n' >"$tmpdir/in/alpha.txt"
printf 'gnu cJf beta  payload\n' >"$tmpdir/in/sub/beta.txt"
sha_alpha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

# GNU tar's own -J path (built-in xz auto-compressor), not piped through xz(1).
tar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" alpha.txt sub/beta.txt

# .xz magic confirms GNU tar wrote a real xz container.
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# bsdtar (libarchive + liblzma) must accept GNU tar's -J output verbatim.
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
test "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')" = "$sha_alpha"
test "$(sha256sum "$tmpdir/out/sub/beta.txt" | awk '{print $1}')" = "$sha_beta"
