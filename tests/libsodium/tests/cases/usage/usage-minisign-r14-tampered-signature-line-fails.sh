#!/usr/bin/env bash
# @testcase: usage-minisign-r14-tampered-signature-line-fails
# @title: minisign -V rejects a .minisig whose signature blob has been tampered
# @description: Generates a passwordless minisign keypair, signs a payload, asserts -V verify succeeds against the original .minisig, then flips the first character of the base64 signature blob inside the .minisig file and asserts -V exits non-zero against the tampered signature file (payload itself unchanged).
# @timeout: 180
# @tags: usage, minisign, verify, tamper
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/m.pub" -s "$tmpdir/m.sec"

printf 'r14 minisign tampered-sig payload\n' >"$tmpdir/msg.txt"
minisign -Sm "$tmpdir/msg.txt" -s "$tmpdir/m.sec" -x "$tmpdir/msg.txt.minisig"

# Baseline: original .minisig verifies.
minisign -Vm "$tmpdir/msg.txt" -p "$tmpdir/m.pub" -x "$tmpdir/msg.txt.minisig" \
  >"$tmpdir/v.out"
validator_assert_contains "$tmpdir/v.out" 'Signature and comment signature verified'

# .minisig file format:
#   line 1: "untrusted comment: ..."
#   line 2: base64-encoded signature blob (the bit we tamper)
#   line 3: "trusted comment: ..."
#   line 4: base64-encoded global signature
sigline=$(LC_ALL=C sed -n '2p' "$tmpdir/msg.txt.minisig")
[[ -n "$sigline" ]]

# Flip the first base64 character of the signature line: A<->B; otherwise prepend 'A'.
first=${sigline:0:1}
case "$first" in
  A) flipped="B${sigline:1}" ;;
  *) flipped="A${sigline:1}" ;;
esac
[[ "$flipped" != "$sigline" ]]

# Splice the tampered signature line back into the file.
cp "$tmpdir/msg.txt.minisig" "$tmpdir/tampered.minisig"
LC_ALL=C awk -v repl="$flipped" 'NR==2{print repl; next}{print}' \
  "$tmpdir/msg.txt.minisig" >"$tmpdir/tampered.minisig"

# .minisig with a corrupted signature blob must NOT verify.
if minisign -Vm "$tmpdir/msg.txt" -p "$tmpdir/m.pub" -x "$tmpdir/tampered.minisig" \
   >"$tmpdir/bad.out" 2>&1; then
  echo 'verify unexpectedly accepted tampered .minisig' >&2
  cat "$tmpdir/bad.out" >&2
  exit 1
fi
