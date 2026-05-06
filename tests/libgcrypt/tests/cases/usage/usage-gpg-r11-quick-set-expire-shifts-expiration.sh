#!/usr/bin/env bash
# @testcase: usage-gpg-r11-quick-set-expire-shifts-expiration
# @title: gpg --quick-set-expire shifts the primary key expiration timestamp
# @description: Generates a 2-day key, runs --quick-set-expire on its fingerprint to push the expiration to 30 days, and verifies the colons-mode pub record's expire field grew by at least 24 days worth of seconds.
# @timeout: 240
# @tags: usage, gpg, quick-set-expire, expiration
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R11 expire <r11-expire@example.invalid>'

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 2d >/dev/null 2>&1

fpr=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')
before=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="pub"{print $7; exit}')

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-set-expire "$fpr" 30d >/dev/null 2>&1

after=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="pub"{print $7; exit}')

[[ -n "$before" && -n "$after" ]] || {
  printf 'missing expire field (before=%s after=%s)\n' "$before" "$after" >&2
  exit 1
}

delta=$(( after - before ))
# 30d - 2d = 28d = 2419200s; require >= 24d worth (2073600s) to allow tiny clock skew.
[[ "$delta" -ge 2073600 ]] || {
  printf 'expire delta too small: before=%s after=%s delta=%s\n' "$before" "$after" "$delta" >&2
  exit 1
}
