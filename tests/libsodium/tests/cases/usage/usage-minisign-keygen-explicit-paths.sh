#!/usr/bin/env bash
# @testcase: usage-minisign-keygen-explicit-paths
# @title: minisign -G writes keys to explicit -p and -s paths
# @description: Runs minisign -G -W with a passwordless keypair into nested -p and -s file paths inside a tmpdir, asserts both files were created at exactly the requested locations (and not next to a default location), that the public key file is a two-line text file whose second line is base64 of plausible length, and that the secret key file's untrusted comment header begins with the documented "untrusted comment:" prefix.
# @timeout: 180
# @tags: usage, crypto, keygen, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/keys/sub"
pub="$tmpdir/keys/sub/explicit.pub"
sec="$tmpdir/keys/sub/explicit.sec"

minisign -G -W -p "$pub" -s "$sec"

validator_require_file "$pub"
validator_require_file "$sec"

# minisign must not also create default-named keys alongside.
if [[ -e "$tmpdir/minisign.pub" ]]; then
  echo "unexpected default minisign.pub created" >&2
  exit 1
fi
if [[ -e "$tmpdir/.minisign/minisign.key" ]]; then
  echo "unexpected default secret created" >&2
  exit 1
fi

# Public key file: two lines, second line base64 of plausible Ed25519+keyid length.
pub_lines=$(wc -l <"$pub")
if (( pub_lines < 2 )); then
  echo "public key file has too few lines: $pub_lines" >&2
  exit 1
fi
key_line=$(sed -n '2p' "$pub")
if [[ ${#key_line} -lt 40 ]]; then
  echo "minisign public key line too short: ${#key_line}" >&2
  exit 1
fi

# Secret key file starts with the documented "untrusted comment:" header.
first=$(sed -n '1p' "$sec")
case "$first" in
  "untrusted comment:"*) ;;
  *)
    echo "unexpected first line of secret key: $first" >&2
    exit 1
    ;;
esac

# The generated key actually works end-to-end.
printf 'explicit-paths payload\n' >"$tmpdir/msg.txt"
minisign -Sm "$tmpdir/msg.txt" -s "$sec" -x "$tmpdir/msg.txt.minisig"
minisign -Vm "$tmpdir/msg.txt" -p "$pub" -x "$tmpdir/msg.txt.minisig" >"$tmpdir/verify.out"
validator_assert_contains "$tmpdir/verify.out" 'Signature and comment signature verified'

echo "ok ${#key_line}"
