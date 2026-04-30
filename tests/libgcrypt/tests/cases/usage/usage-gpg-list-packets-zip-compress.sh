#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-zip-compress
# @title: gpg --list-packets shows ZIP compression algo
# @description: Symmetrically encrypts a payload with --compress-algo ZIP and uses --list-packets (with the symmetric passphrase) to decode the inner packets, asserting the compressed packet uses algo=1 (ZIP).
# @timeout: 180
# @tags: usage, gpg, packets
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-zip-compress"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase

printf 'compressible payload AAAAAAAAAAAAAAAAAAAA BBBBBBBBBBBBBBBBBBBB\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase "$passphrase" --compress-algo ZIP --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/packets" ':compressed packet: algo=1'
validator_assert_contains "$tmpdir/packets" ':literal data packet:'
