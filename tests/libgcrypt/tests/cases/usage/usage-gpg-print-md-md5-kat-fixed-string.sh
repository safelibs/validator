#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-md5-kat-fixed-string
# @title: gpg print-md MD5 fixed-string KAT
# @description: Verifies gpg --print-md MD5 emits the canonical 5d41402abc4b2a76b9719d9110175c592 known-answer digest for the literal input "hello".
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-md5-kat-fixed-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# Exactly "hello" with no trailing newline -> MD5 = 5d41402abc4b2a76b9719d911017c592
printf 'hello' >"$tmpdir/hello.txt"
size=$(wc -c <"$tmpdir/hello.txt" | tr -d ' ')
test "$size" = "5"

gpg --print-md MD5 "$tmpdir/hello.txt" >"$tmpdir/out"

hex=$(tr -d ' \t\n' <"$tmpdir/out" | sed 's/^.*://')
test "$hex" = "5D41402ABC4B2A76B9719D911017C592"

validator_assert_contains "$tmpdir/out" 'hello.txt:'
validator_assert_contains "$tmpdir/out" '5D 41 40 2A BC 4B 2A 76'
validator_assert_contains "$tmpdir/out" 'B9 71 9D 91 10 17 C5 92'
