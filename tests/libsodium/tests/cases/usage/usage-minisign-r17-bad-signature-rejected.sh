#!/usr/bin/env bash
# @testcase: usage-minisign-r17-bad-signature-rejected
# @title: minisign -V rejects a signature taken from a different payload as invalid
# @description: Generates a passwordless minisign keypair, signs payload A, then runs minisign -V against payload B using A's signature file copied alongside payload B, and asserts the verifier exits with non-zero status because the signature does not match the modified payload, confirming libsodium signature failure surfacing.
# @timeout: 60
# @tags: usage, minisign, verify, negative, r17
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r17 payload A\n' >"$tmpdir/a.txt"
printf 'r17 payload B different\n' >"$tmpdir/b.txt"

minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/a.txt" -W </dev/null >/dev/null
[[ -s "$tmpdir/a.txt.minisig" ]]

cp "$tmpdir/a.txt.minisig" "$tmpdir/b.txt.minisig"

set +e
minisign -V -p "$tmpdir/k.pub" -m "$tmpdir/b.txt" >"$tmpdir/verify.out" 2>&1
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  printf 'expected non-zero exit, got 0\n' >&2
  cat "$tmpdir/verify.out" >&2
  exit 1
fi
echo "ok rejected rc=$rc"
