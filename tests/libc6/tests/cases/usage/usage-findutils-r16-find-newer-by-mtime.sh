#!/usr/bin/env bash
# @testcase: usage-findutils-r16-find-newer-by-mtime
# @title: find -newer selects files modified after a reference touchstone
# @description: Creates a reference file, sleeps briefly, creates a second file, and asserts find -newer reference reports only the later file — locking in the relative-mtime selection that depends on libc stat semantics.
# @timeout: 30
# @tags: usage, findutils, newer, mtime
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Search directory and output file are kept disjoint so the output file does
# not accidentally satisfy its own -newer predicate.
search="$tmpdir/search"
mkdir "$search"

touch "$search/old.txt"
touch -t 200001010000 "$search/old.txt"

touch "$search/reference"
# Ensure mtime resolution gap.
sleep 1
touch "$search/new.txt"

find "$search" -type f -newer "$search/reference" -printf '%f\n' | sort >"$tmpdir/hits"

# Reference itself is not strictly newer than itself; only new.txt qualifies.
mapfile -t lines <"$tmpdir/hits"
[[ "${#lines[@]}" -eq 1 ]] || {
    printf 'expected 1 newer file, got %s\n' "${#lines[@]}" >&2
    cat "$tmpdir/hits" >&2
    exit 1
}
[[ "${lines[0]}" == "new.txt" ]]
