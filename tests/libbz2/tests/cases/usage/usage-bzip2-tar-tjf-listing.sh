#!/usr/bin/env bash
# @testcase: usage-bzip2-tar-tjf-listing
# @title: tar -tjf lists members of a bzip2 archive
# @description: Builds a bzip2-compressed tarball and verifies tar -tjf prints exactly the expected member names in order without extracting.
# @timeout: 180
# @tags: usage, bzip2, tar, listing
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/alpha.txt"
printf 'beta\n'  >"$tmpdir/src/beta.txt"
printf 'gamma\n' >"$tmpdir/src/gamma.txt"

tar -C "$tmpdir/src" -cjf "$tmpdir/three.tar.bz2" alpha.txt beta.txt gamma.txt

# Listing must succeed without writing any files into a sibling directory.
mkdir "$tmpdir/probe"
( cd "$tmpdir/probe" && tar -tjf "$tmpdir/three.tar.bz2" ) >"$tmpdir/list.out"

# Probe directory must remain empty - listing should not extract anything.
shopt -s nullglob dotglob
probe_entries=( "$tmpdir/probe"/* )
shopt -u nullglob dotglob
if (( ${#probe_entries[@]} != 0 )); then
  printf 'tar -tjf unexpectedly created files in probe dir:\n' >&2
  printf '  %s\n' "${probe_entries[@]}" >&2
  exit 1
fi

printf 'alpha.txt\nbeta.txt\ngamma.txt\n' >"$tmpdir/expected"
cmp "$tmpdir/list.out" "$tmpdir/expected"
