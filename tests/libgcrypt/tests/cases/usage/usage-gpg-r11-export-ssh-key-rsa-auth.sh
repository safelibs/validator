#!/usr/bin/env bash
# @testcase: usage-gpg-r11-export-ssh-key-rsa-auth
# @title: gpg --export-ssh-key emits ssh-rsa public key from auth-capable RSA key
# @description: Generates a 2048-bit RSA key with the auth usage flag and verifies --export-ssh-key produces a single line beginning with "ssh-rsa " followed by base64 material.
# @timeout: 300
# @tags: usage, gpg, ssh, rsa
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R11 ssh-auth <r11-ssh@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" rsa2048 auth 1d >/dev/null 2>&1

gpg --batch --export-ssh-key "$uid" >"$tmpdir/id.pub" 2>"$tmpdir/err"
[[ -s "$tmpdir/id.pub" ]] || { cat "$tmpdir/err" >&2; exit 1; }

first_line=$(head -n 1 "$tmpdir/id.pub")
case "$first_line" in
  'ssh-rsa AAAA'*) : ;;
  *)
    printf 'unexpected ssh-export header: %s\n' "$first_line" >&2
    exit 1
    ;;
esac

# At least 200 chars of base64 material before any trailing comment.
len=${#first_line}
[[ "$len" -ge 250 ]] || {
  printf 'ssh-export line shorter than expected (%d chars): %s\n' "$len" "$first_line" >&2
  exit 1
}
