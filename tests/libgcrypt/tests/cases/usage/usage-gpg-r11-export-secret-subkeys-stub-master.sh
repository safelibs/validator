#!/usr/bin/env bash
# @testcase: usage-gpg-r11-export-secret-subkeys-stub-master
# @title: gpg --export-secret-subkeys produces a gnu-dummy stub primary
# @description: Generates a default key (ed25519 SC + cv25519 E) and verifies that --export-secret-subkeys yields a packet stream whose first secret key packet carries the gnu-dummy marker, indicating the master secret has been redacted to a stub.
# @timeout: 240
# @tags: usage, gpg, export-secret-subkeys, stub
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R11 stub <r11-stub@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

fpr=$(gpg --batch --with-colons --list-keys | awk -F: '$1=="fpr"{print $10; exit}')

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --export-secret-subkeys "$fpr" >"$tmpdir/sec-sub.gpg" 2>/dev/null
[[ -s "$tmpdir/sec-sub.gpg" ]] || { echo 'empty export' >&2; exit 1; }

gpg --batch --list-packets "$tmpdir/sec-sub.gpg" >"$tmpdir/packets" 2>&1

# Pull out the first ":secret key packet:" stanza and confirm it contains gnu-dummy.
awk '
  /:secret (key|subkey) packet:/ { sec++; in_pkt = (sec == 1) ? 1 : 0; next }
  /^# off=/ { in_pkt = 0 }
  in_pkt { print }
' "$tmpdir/packets" >"$tmpdir/first-secret"

grep -q 'gnu-dummy' "$tmpdir/first-secret" || {
  echo 'first secret key packet is not a gnu-dummy stub' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}
