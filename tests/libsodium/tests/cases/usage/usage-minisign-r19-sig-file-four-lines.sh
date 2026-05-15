#!/usr/bin/env bash
# @testcase: usage-minisign-r19-sig-file-four-lines
# @title: minisign signature file structure has untrusted comment, sig blob, trusted comment, and global sig
# @description: Generates a passwordless keypair, signs a payload, and asserts the resulting .minisig file has exactly four content lines: line 1 begins with "untrusted comment:", line 2 is a non-empty base64 blob, line 3 begins with "trusted comment:", and line 4 is a non-empty base64 blob, confirming minisign's documented signature container layout.
# @timeout: 60
# @tags: usage, minisign, sig, layout, r19
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r19 sig layout payload\n' >"$tmpdir/m.txt"

minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -W </dev/null >/dev/null

sig="$tmpdir/m.txt.minisig"
[[ -s "$sig" ]]

line_count=$(wc -l <"$sig")
[[ "$line_count" -eq 4 ]] || { echo "unexpected line_count=$line_count" >&2; cat "$sig" >&2; exit 1; }

line1=$(sed -n '1p' "$sig")
line2=$(sed -n '2p' "$sig")
line3=$(sed -n '3p' "$sig")
line4=$(sed -n '4p' "$sig")

[[ "$line1" == "untrusted comment: "* ]] || { echo "bad line1: $line1" >&2; exit 1; }
[[ -n "$line2" ]] || { echo "empty line2" >&2; exit 1; }
[[ "$line3" == "trusted comment: "* ]] || { echo "bad line3: $line3" >&2; exit 1; }
[[ -n "$line4" ]] || { echo "empty line4" >&2; exit 1; }

echo "ok sig layout"
