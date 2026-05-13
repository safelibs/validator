#!/usr/bin/env bash
# @testcase: usage-gpg-r16-enarmor-dearmor-perl-bytes-roundtrip
# @title: gpg --enarmor then --dearmor recovers a 256-byte perl-built ramp
# @description: Builds a deterministic 256-byte ramp (0..255) via perl, runs gpg --enarmor and gpg --dearmor under an ephemeral GNUPGHOME, and asserts the recovered bytes are byte-identical to the original via cmp — a longer payload than the r14 128-byte variant.
# @timeout: 60
# @tags: usage, gpg, enarmor, dearmor, perl
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

LC_ALL=C perl -e 'for ($i = 0; $i < 256; $i++) { print chr($i); }' >"$tmpdir/ramp.bin"
[[ "$(wc -c <"$tmpdir/ramp.bin")" -eq 256 ]]

gpg --batch --enarmor <"$tmpdir/ramp.bin" >"$tmpdir/ramp.asc" 2>/dev/null
gpg --batch --dearmor <"$tmpdir/ramp.asc" >"$tmpdir/recovered.bin" 2>/dev/null

cmp "$tmpdir/ramp.bin" "$tmpdir/recovered.bin"
