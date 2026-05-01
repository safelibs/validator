#!/usr/bin/env bash
# @testcase: usage-findutils-regex-extended
# @title: findutils -regextype posix-extended match
# @description: Filters a directory tree with find -regextype posix-extended using an alternation pattern and confirms only matching paths are emitted.
# @timeout: 60
# @tags: usage, findutils, regex
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-regex-extended"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/note.txt"
: >"$tmpdir/tree/photo.jpg"
: >"$tmpdir/tree/photo.png"
: >"$tmpdir/tree/script.sh"

find "$tmpdir/tree" -type f -regextype posix-extended -regex '.*\.(jpg|png)$' \
  | sort >"$tmpdir/out"

{ printf '%s\n' "$tmpdir/tree/photo.jpg" "$tmpdir/tree/photo.png"; } | sort >"$tmpdir/expected"
cmp "$tmpdir/expected" "$tmpdir/out"
