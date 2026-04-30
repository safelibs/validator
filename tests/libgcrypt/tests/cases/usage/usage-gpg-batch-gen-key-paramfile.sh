#!/usr/bin/env bash
# @testcase: usage-gpg-batch-gen-key-paramfile
# @title: gpg --batch --gen-key from parameter file
# @description: Generates an ed25519 signing key non-interactively via gpg --batch --gen-key fed a parameter control file on stdin, then asserts the public key listing reflects the requested UID.
# @timeout: 240
# @tags: usage, gpg, keygen
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-batch-gen-key-paramfile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

paramfile="$tmpdir/keyparams"
cat >"$paramfile" <<'EOF'
%no-protection
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: sign
Name-Real: Param Generated
Name-Email: paramgen@example.invalid
Expire-Date: 1d
%commit
EOF

# Feed the parameter file on stdin to exercise that delivery path explicitly.
gpg --batch --pinentry-mode loopback --gen-key <"$paramfile"

gpg --list-keys --with-colons >"$tmpdir/keys.colons"
validator_assert_contains "$tmpdir/keys.colons" 'paramgen@example.invalid'

gpg --list-keys "paramgen@example.invalid" >"$tmpdir/keys.txt"
validator_assert_contains "$tmpdir/keys.txt" 'Param Generated'
