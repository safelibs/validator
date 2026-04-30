#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha512-empty-kat
# @title: gpg print-md SHA512 empty input KAT
# @description: Verifies gpg --print-md SHA512 emits the canonical cf83e135... known-answer digest for an empty input file.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha512-empty-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
test ! -s "$tmpdir/empty.bin"

gpg --print-md SHA512 "$tmpdir/empty.bin" >"$tmpdir/out"

# Canonical SHA-512 of the empty string:
# cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce
# 47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e
hex=$(tr -d ' \t\n' <"$tmpdir/out" | sed 's/^.*://')
expected="CF83E1357EEFB8BDF1542850D66D8007D620E4050B5715DC83F4A921D36CE9CE47D0D13C5D85F2B0FF8318D2877EEC2F63B931BD47417A81A538327AF927DA3E"
test "$hex" = "$expected"

validator_assert_contains "$tmpdir/out" 'empty.bin:'
validator_assert_contains "$tmpdir/out" 'CF83E135'
validator_assert_contains "$tmpdir/out" 'F927DA3E'
