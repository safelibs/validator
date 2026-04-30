#!/usr/bin/env bash
# @testcase: usage-minisign-verify-mismatch-fails
# @title: minisign -V on a tampered file fails
# @description: Generates a passwordless minisign keypair, signs the genuine file, and asserts that minisign -V exits non-zero when invoked against a tampered copy of the file (same .minisig, different bytes), and that the verifier's stderr output mentions a verification failure rather than a successful banner.
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'minisign genuine payload\n' >"$tmpdir/message.txt"
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -x "$tmpdir/message.txt.minisig"
validator_require_file "$tmpdir/message.txt.minisig"

# Sanity: genuine verify succeeds.
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" >"$tmpdir/genuine.out"
validator_assert_contains "$tmpdir/genuine.out" 'Signature and comment signature verified'

# Now tamper with the message file: same signature, different bytes.
printf 'minisign tampered payload\n' >"$tmpdir/message.txt"

# Verification must fail. minisign exits non-zero and writes a failure note to stderr.
set +e
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" >"$tmpdir/bad.out" 2>"$tmpdir/bad.err"
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  printf 'minisign -V unexpectedly succeeded on tampered file\n' >&2
  cat "$tmpdir/bad.out" "$tmpdir/bad.err" >&2 || true
  exit 1
fi

if grep -q 'Signature and comment signature verified' "$tmpdir/bad.out" "$tmpdir/bad.err" 2>/dev/null; then
  printf 'minisign reported verified banner on tampered file\n' >&2
  cat "$tmpdir/bad.out" "$tmpdir/bad.err" >&2
  exit 2
fi

# Expect a failure-mention on stderr; minisign prints something containing "verification" / "fail" / "Signature".
if ! grep -Eqi 'fail|invalid|forged|signature' "$tmpdir/bad.err"; then
  printf 'unexpected minisign stderr on tampered verify:\n' >&2
  cat "$tmpdir/bad.err" >&2
  exit 3
fi

echo "ok rc=$rc"
