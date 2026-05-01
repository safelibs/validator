#!/usr/bin/env bash
# @testcase: usage-minisign-untrusted-comment
# @title: minisign -S -c writes the untrusted comment to the .minisig
# @description: Generates a passwordless keypair, signs a payload with -S -c "<untrusted text>", and asserts that the resulting .minisig file's first line carries the documented "untrusted comment:" header followed by the supplied text. Confirms libsodium-backed minisign honours the -c override for the unsigned (untrusted) comment field.
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'untrusted-comment payload\n' >"$tmpdir/message.txt"
minisign -G -W -p "$tmpdir/m.pub" -s "$tmpdir/m.sec"

unt='validator untrusted note 42'
minisign -Sm "$tmpdir/message.txt" \
  -s "$tmpdir/m.sec" \
  -c "$unt" \
  -x "$tmpdir/message.txt.minisig"

validator_require_file "$tmpdir/message.txt.minisig"

first=$(sed -n '1p' "$tmpdir/message.txt.minisig")
case "$first" in
  "untrusted comment: "*) ;;
  *)
    echo "missing untrusted comment header: $first" >&2
    exit 1
    ;;
esac

if ! grep -Fq "$unt" "$tmpdir/message.txt.minisig"; then
  echo "supplied untrusted comment not found in minisig" >&2
  cat "$tmpdir/message.txt.minisig" >&2
  exit 1
fi

# End-to-end verification still works with the custom comment.
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/m.pub" -x "$tmpdir/message.txt.minisig" >"$tmpdir/v.out"
validator_assert_contains "$tmpdir/v.out" 'Signature and comment signature verified'

echo "ok"
