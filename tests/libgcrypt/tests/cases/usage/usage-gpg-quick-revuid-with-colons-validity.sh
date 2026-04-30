#!/usr/bin/env bash
# @testcase: usage-gpg-quick-revuid-with-colons-validity
# @title: gpg --quick-revuid surfaces validity 'r' in colon listing
# @description: Adds a second user id to a generated key, revokes it with --quick-revuid, and confirms the machine-readable colon listing reports the revoked uid with validity field 'r' while the primary uid retains 'u'.
# @timeout: 240
# @tags: usage, gpg, keyring, revocation
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-quick-revuid-with-colons-validity"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
primary='Validator RevColons <validator-rev-colons@example.invalid>'
extra='Validator Extra Colons <validator-extra-colons@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$primary" default default 1d >/dev/null 2>&1
"${gpg_batch[@]}" --passphrase '' \
  --quick-add-uid "$primary" "$extra" >/dev/null 2>&1

# Sanity: the extra uid is present and live before revocation.
gpg --with-colons --list-keys "$primary" >"$tmpdir/before"
grep -E '^uid:[^:]*:' "$tmpdir/before" \
  | awk -F: -v u="$extra" '$10==u {print $2; found=1} END {exit found?0:1}' \
  >"$tmpdir/before.validity"
grep -qE '^[u-]$' "$tmpdir/before.validity"

# Revoke the extra uid.
"${gpg_batch[@]}" --passphrase '' \
  --quick-revuid "$primary" "$extra" >/dev/null 2>&1

# After revocation the colon listing must report validity 'r' for the extra
# uid. The primary uid must remain trusted ('u').
gpg --with-colons --list-keys "$primary" >"$tmpdir/after"

primary_validity=$(grep -E '^uid:[^:]*:' "$tmpdir/after" \
  | awk -F: -v u="$primary" '$10==u {print $2; exit}')
extra_validity=$(grep -E '^uid:[^:]*:' "$tmpdir/after" \
  | awk -F: -v u="$extra" '$10==u {print $2; exit}')

if [[ "$primary_validity" != "u" ]]; then
  printf 'primary uid validity changed unexpectedly: %q\n' "$primary_validity" >&2
  cat "$tmpdir/after" >&2
  exit 1
fi
if [[ "$extra_validity" != "r" ]]; then
  printf 'revoked uid validity is %q, expected r\n' "$extra_validity" >&2
  cat "$tmpdir/after" >&2
  exit 1
fi
