#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha256-empty-kat
# @title: gpg print-md SHA256 empty input KAT
# @description: Verifies gpg --print-md SHA256 emits the canonical e3b0c442... known-answer digest for an empty input file.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha256-empty-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

: >"$tmpdir/empty.bin"
test ! -s "$tmpdir/empty.bin"

gpg --print-md SHA256 "$tmpdir/empty.bin" >"$tmpdir/out"

# Canonical SHA-256 of the empty string:
# e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
hex=$(tr -d ' \t\n' <"$tmpdir/out" | sed 's/^.*://')
test "$hex" = "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"

validator_assert_contains "$tmpdir/out" 'empty.bin:'
validator_assert_contains "$tmpdir/out" 'E3B0C442'
validator_assert_contains "$tmpdir/out" '7852B855'
