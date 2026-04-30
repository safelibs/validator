#!/usr/bin/env bash
# @testcase: usage-minisign-stripped-trusted-comment-fails
# @title: minisign -V rejects signature with a stripped trusted_comment
# @description: Signs a payload with minisign using -t to embed a custom trusted_comment, confirms the genuine .minisig file verifies and that the trusted comment is exposed by -Vm output, then constructs a mutated .minisig with the trusted_comment line and its global comment-signature line removed and asserts minisign -V exits non-zero on it. minisign's two-signature design covers both the message and the trusted comment, so any edit to the trusted_comment must cause verification to fail rather than produce a partial pass.
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'minisign trusted-comment stripping payload\n' >"$tmpdir/message.txt"
minisign -G -W -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec"
minisign -Sm "$tmpdir/message.txt" \
    -s "$tmpdir/minisign.sec" \
    -t 'validator-trusted-comment-1234' \
    -x "$tmpdir/message.txt.minisig"
validator_require_file "$tmpdir/message.txt.minisig"

# Genuine verify succeeds and the trusted comment is shown.
minisign -Vm "$tmpdir/message.txt" \
    -p "$tmpdir/minisign.pub" \
    -x "$tmpdir/message.txt.minisig" >"$tmpdir/genuine.out"
validator_assert_contains "$tmpdir/genuine.out" 'Signature and comment signature verified'
validator_assert_contains "$tmpdir/genuine.out" 'validator-trusted-comment-1234'

# Sanity: genuine .minisig has the documented "trusted comment:" line.
if ! grep -q '^trusted comment:' "$tmpdir/message.txt.minisig"; then
    printf 'genuine .minisig missing trusted comment line\n' >&2
    cat "$tmpdir/message.txt.minisig" >&2
    exit 1
fi

# Build a stripped variant of the .minisig: keep header lines, drop the
# trusted_comment line and the final base64 global signature line.
grep -v '^trusted comment:' "$tmpdir/message.txt.minisig" >"$tmpdir/stripped.minisig"
# minisign .minisig has 4 lines: untrusted comment, sig-base64, trusted comment, global-sig-base64.
# After dropping trusted comment we still have 3 lines; drop the last (global sig) too.
total=$(wc -l <"$tmpdir/stripped.minisig")
if (( total < 2 )); then
    printf 'stripped .minisig has too few lines: %s\n' "$total" >&2
    cat "$tmpdir/stripped.minisig" >&2
    exit 1
fi
keep=$(( total - 1 ))
head -n "$keep" "$tmpdir/stripped.minisig" >"$tmpdir/stripped2.minisig"
mv "$tmpdir/stripped2.minisig" "$tmpdir/stripped.minisig"

if grep -q '^trusted comment:' "$tmpdir/stripped.minisig"; then
    printf 'stripped .minisig still has trusted comment line\n' >&2
    exit 2
fi

set +e
minisign -Vm "$tmpdir/message.txt" \
    -p "$tmpdir/minisign.pub" \
    -x "$tmpdir/stripped.minisig" >"$tmpdir/bad.out" 2>"$tmpdir/bad.err"
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
    printf 'minisign -V unexpectedly succeeded on stripped trusted comment\n' >&2
    cat "$tmpdir/bad.out" "$tmpdir/bad.err" >&2 || true
    exit 3
fi

if grep -q 'Signature and comment signature verified' "$tmpdir/bad.out" "$tmpdir/bad.err" 2>/dev/null; then
    printf 'verifier reported success banner despite stripped trusted comment\n' >&2
    cat "$tmpdir/bad.out" "$tmpdir/bad.err" >&2
    exit 4
fi

echo "ok rc=$rc"
