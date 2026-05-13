#!/usr/bin/env bash
# @testcase: usage-minisign-r16-keygen-creates-both-key-files
# @title: minisign -G -W writes both public and secret key files into specified paths
# @description: Runs minisign -G -W with explicit -p and -s paths under a temporary directory, asserts both files exist, are regular files, are non-empty, that the public key file begins with the "untrusted comment" banner and the secret key file likewise begins with the banner identifying it as a minisign encrypted secret key block.
# @timeout: 60
# @tags: usage, minisign, keygen, r16
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pub="$tmpdir/r16.pub"
sec="$tmpdir/r16.sec"
minisign -G -W -p "$pub" -s "$sec" >/dev/null

[[ -f "$pub" ]]
[[ -f "$sec" ]]
[[ -s "$pub" ]]
[[ -s "$sec" ]]

pub_line1=$(LC_ALL=C sed -n '1p' "$pub")
sec_line1=$(LC_ALL=C sed -n '1p' "$sec")

[[ "$pub_line1" == untrusted\ comment:* ]] || {
  printf 'unexpected pub line 1: %s\n' "$pub_line1" >&2
  exit 1
}
[[ "$sec_line1" == untrusted\ comment:* ]] || {
  printf 'unexpected sec line 1: %s\n' "$sec_line1" >&2
  exit 1
}
