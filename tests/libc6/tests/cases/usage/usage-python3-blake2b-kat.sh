#!/usr/bin/env bash
# @testcase: usage-python3-blake2b-kat
# @title: python3 hashlib blake2b known-answer test
# @description: Computes BLAKE2b-512 of "abc" via hashlib and compares to the published reference digest.
# @timeout: 180
# @tags: usage, python3, crypto
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-blake2b-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import hashlib; print(hashlib.blake2b(b"abc").hexdigest())' >"$tmpdir/out"

expected='ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923'
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"
