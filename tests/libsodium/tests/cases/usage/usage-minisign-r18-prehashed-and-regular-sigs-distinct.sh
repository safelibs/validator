#!/usr/bin/env bash
# @testcase: usage-minisign-r18-prehashed-and-regular-sigs-distinct
# @title: minisign prehashed (-H) and regular signature files differ in algorithm marker
# @description: Generates a passwordless keypair, signs the same payload once with the default algorithm and once with the prehashed (-H) algorithm into distinct output paths, asserts both signature files exist, asserts their full bytes differ, and asserts the first base64 line of each decodes to a 2-byte algorithm marker that differs between the two files (Ed vs ED).
# @timeout: 60
# @tags: usage, minisign, sign, prehashed, r18
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r18 prehashed vs regular payload\n' >"$tmpdir/m.txt"

minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -x "$tmpdir/regular.sig" -W </dev/null >/dev/null
minisign -S -H -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -x "$tmpdir/prehash.sig" -W </dev/null >/dev/null

[[ -s "$tmpdir/regular.sig" ]]
[[ -s "$tmpdir/prehash.sig" ]]

if cmp -s "$tmpdir/regular.sig" "$tmpdir/prehash.sig"; then
  printf 'regular and prehashed signatures are byte-identical\n' >&2
  exit 1
fi

regular_marker=$(grep -v '^untrusted comment' "$tmpdir/regular.sig" | head -n1 | base64 -d 2>/dev/null | head -c2 | od -An -c | tr -d ' \n')
prehash_marker=$(grep -v '^untrusted comment' "$tmpdir/prehash.sig" | head -n1 | base64 -d 2>/dev/null | head -c2 | od -An -c | tr -d ' \n')

if [[ -z "$regular_marker" || -z "$prehash_marker" ]]; then
  printf 'failed to extract algorithm marker\n' >&2
  exit 1
fi

if [[ "$regular_marker" == "$prehash_marker" ]]; then
  printf 'markers identical regular=%s prehash=%s\n' "$regular_marker" "$prehash_marker" >&2
  exit 1
fi

echo "ok regular=$regular_marker prehash=$prehash_marker"
