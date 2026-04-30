#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch15-stdout-archive-sha-verify
# @title: bsdtar xz to /dev/stdout with sha verification
# @description: Streams a tar.xz to /dev/stdout (redirected to a file), confirms .xz magic on the captured stream, then extracts it and verifies the sha256 of every input survives the round-trip.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
printf 'stdout alpha\n' >"$tmpdir/in/alpha.txt"
printf 'stdout beta\n'  >"$tmpdir/in/sub/beta.txt"

sha_alpha_in=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
sha_beta_in=$(sha256sum "$tmpdir/in/sub/beta.txt" | awk '{print $1}')

# Write the archive explicitly to /dev/stdout, redirecting stdout to a file.
# This exercises the named-stdout path rather than the bare "-" sentinel.
bsdtar -cJf /dev/stdout -C "$tmpdir/in" alpha.txt sub/beta.txt \
  >"$tmpdir/captured.tar.xz"

# Captured archive must be a real .xz container.
magic_hex=$(head -c 6 "$tmpdir/captured.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# Non-empty.
test "$(stat -c %s "$tmpdir/captured.tar.xz")" -gt 0

# Round-trip extraction; sha256 of every input must match its extract.
bsdtar -xf "$tmpdir/captured.tar.xz" -C "$tmpdir/out"

sha_alpha_out=$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')
sha_beta_out=$(sha256sum "$tmpdir/out/sub/beta.txt" | awk '{print $1}')

test "$sha_alpha_in" = "$sha_alpha_out"
test "$sha_beta_in"  = "$sha_beta_out"
