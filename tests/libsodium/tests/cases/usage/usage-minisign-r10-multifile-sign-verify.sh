#!/usr/bin/env bash
# @testcase: usage-minisign-r10-multifile-sign-verify
# @title: minisign signs and verifies three independent files
# @description: Generates a passwordless minisign keypair, signs three distinct payload files in separate invocations, verifies each signature against the public key, and asserts the three .minisig files have distinct contents (different signatures even though they share a key).
# @timeout: 180
# @tags: usage, minisign, crypto, multi
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/pk" -s "$tmpdir/sk" >/dev/null

for i in 1 2 3; do
    printf 'minisign r10 multifile payload number %d\n' "$i" >"$tmpdir/file$i.txt"
    minisign -S -W -s "$tmpdir/sk" -m "$tmpdir/file$i.txt" >/dev/null
    [[ -f "$tmpdir/file$i.txt.minisig" ]] || { echo "no signature for file$i" >&2; exit 1; }
    minisign -V -p "$tmpdir/pk" -m "$tmpdir/file$i.txt" >"$tmpdir/v$i.log"
    validator_assert_contains "$tmpdir/v$i.log" 'Signature and comment signature verified'
done

# Three files signed independently must produce three distinct signature files.
hash1=$(sha256sum "$tmpdir/file1.txt.minisig" | awk '{print $1}')
hash2=$(sha256sum "$tmpdir/file2.txt.minisig" | awk '{print $1}')
hash3=$(sha256sum "$tmpdir/file3.txt.minisig" | awk '{print $1}')

[[ "$hash1" != "$hash2" ]] || { echo "sig1 == sig2" >&2; exit 2; }
[[ "$hash1" != "$hash3" ]] || { echo "sig1 == sig3" >&2; exit 2; }
[[ "$hash2" != "$hash3" ]] || { echo "sig2 == sig3" >&2; exit 2; }
echo "ok"
