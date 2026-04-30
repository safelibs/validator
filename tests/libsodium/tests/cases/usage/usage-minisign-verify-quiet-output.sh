#!/usr/bin/env bash
# @testcase: usage-minisign-verify-quiet-output
# @title: minisign -V quiet mode emits no banner on success
# @description: Generates a passwordless minisign keypair, signs a payload, and runs verify with -q (quiet) asserting the verifier exits zero and produces no banner output, while a non-quiet verify on the same artifacts emits the standard "Signature and comment signature verified" banner.
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'minisign quiet verify payload\n' >"$tmpdir/message.txt"
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -x "$tmpdir/message.txt.minisig"
validator_require_file "$tmpdir/message.txt.minisig"

# quiet verify: must succeed and produce no stdout
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" -q >"$tmpdir/quiet.out" 2>"$tmpdir/quiet.err"
if [[ -s "$tmpdir/quiet.out" ]]; then
  printf 'expected empty stdout under -q, got:\n' >&2
  cat "$tmpdir/quiet.out" >&2
  exit 1
fi

# non-quiet verify: must emit the standard banner
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" >"$tmpdir/loud.out"
validator_assert_contains "$tmpdir/loud.out" 'Signature and comment signature verified'
echo "ok"
