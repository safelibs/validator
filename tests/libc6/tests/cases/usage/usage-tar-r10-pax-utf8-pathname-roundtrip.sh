#!/usr/bin/env bash
# @testcase: usage-tar-r10-pax-utf8-pathname-roundtrip
# @title: tar pax format round-trips a UTF-8 pathname via libc multibyte
# @description: Creates a file with a multi-byte UTF-8 name, archives it with tar --format=pax, extracts it into a fresh directory, and verifies the extracted name and contents match (libc mbrtowc/wcrtomb path).
# @timeout: 60
# @tags: usage, tar, utf8
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src"
out="$tmpdir/out"
mkdir -p "$src" "$out"
name=$'caf\xc3\xa9-naïve.txt'   # UTF-8: café-naïve.txt
printf 'pax-utf8-payload\n' >"$src/$name"

(cd "$src" && tar --format=pax -cf "$tmpdir/a.tar" "$name")
(cd "$out" && tar -xf "$tmpdir/a.tar")

[[ -f "$out/$name" ]]
got=$(cat "$out/$name")
[[ "$got" == "pax-utf8-payload" ]]
