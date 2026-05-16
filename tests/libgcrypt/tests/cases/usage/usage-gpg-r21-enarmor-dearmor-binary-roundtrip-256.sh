#!/usr/bin/env bash
# @testcase: usage-gpg-r21-enarmor-dearmor-binary-roundtrip-256
# @title: gpg --enarmor then --dearmor roundtrips 256 random bytes exactly
# @description: Generates 256 bytes of /dev/urandom into a binary file, pipes them through gpg --enarmor to produce a radix-64 armored block, pipes the armored block back through gpg --dearmor, and asserts the recovered bytes match the original via cmp -s - locking in libgcrypt's radix-64 encode/decode roundtrip path at a 256-byte payload distinct from earlier fixed-blob and perl-bytes roundtrip cases.
# @timeout: 60
# @tags: usage, gpg, enarmor, dearmor, roundtrip, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

head -c 256 /dev/urandom >"$tmpdir/in.bin"
[[ "$(wc -c <"$tmpdir/in.bin")" -eq 256 ]] || { echo 'fixture wrong size' >&2; exit 1; }

gpg --enarmor <"$tmpdir/in.bin" >"$tmpdir/armored.txt" 2>"$tmpdir/enarm.err"
gpg --dearmor <"$tmpdir/armored.txt" >"$tmpdir/out.bin" 2>"$tmpdir/dearm.err"

cmp -s "$tmpdir/in.bin" "$tmpdir/out.bin" || {
    echo 'enarmor/dearmor roundtrip did not recover original bytes' >&2
    ls -l "$tmpdir/in.bin" "$tmpdir/out.bin" >&2
    exit 1
}
