#!/usr/bin/env bash
# @testcase: usage-minisign-r19-verify-quiet-suppresses-banner
# @title: minisign -V -q on a valid signature suppresses the trusted-comment banner on stdout
# @description: Signs a payload, then runs minisign -V -q against the matching pubkey and asserts the verifier exits zero, captures stdout, and asserts stdout does NOT contain the strings "Signature and comment signature verified" or "Trusted comment:", confirming -q (quiet) silences the human-readable success banner while still returning success.
# @timeout: 60
# @tags: usage, minisign, verify, quiet, r19
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r19 quiet verify payload\n' >"$tmpdir/m.txt"
minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -W </dev/null >/dev/null

minisign -V -q -p "$tmpdir/k.pub" -m "$tmpdir/m.txt" >"$tmpdir/out" 2>"$tmpdir/err"

if grep -q "Signature and comment signature verified" "$tmpdir/out"; then
  echo "expected -q to suppress success banner" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

if grep -q "Trusted comment:" "$tmpdir/out"; then
  echo "expected -q to suppress trusted-comment line" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

echo "ok quiet verify"
