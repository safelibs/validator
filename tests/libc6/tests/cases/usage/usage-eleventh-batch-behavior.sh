#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-readarray-lines-batch11)
    printf 'alpha\nbeta\n' >"$tmpdir/in.txt"
    bash -c 'readarray -t rows <"$1"; printf "%s:%s\n" "${#rows[@]}" "${rows[1]}"' _ "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2:beta'
    ;;
  usage-coreutils-stat-size-format-batch11)
    printf 'abcdef' >"$tmpdir/file.txt"
    stat -c 'size=%s' "$tmpdir/file.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'size=6'
    ;;
  usage-coreutils-sort-version-batch11)
    printf 'v2\nv10\nv1\n' >"$tmpdir/in.txt"
    sort -V "$tmpdir/in.txt" >"$tmpdir/out"
    printf 'v1\nv2\nv10\n' >"$tmpdir/expected"
    cmp "$tmpdir/expected" "$tmpdir/out"
    ;;
  usage-grep-extended-alternation-batch11)
    printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
    grep -E '^(alpha|gamma)$' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-gawk-strftime-epoch-batch11)
    TZ=UTC gawk 'BEGIN { print strftime("%Y-%m-%d", 0) }' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1970-01-01'
    ;;
  usage-sed-transliterate-batch11)
    printf 'abc xyz\n' >"$tmpdir/in.txt"
    sed 'y/abc/ABC/' "$tmpdir/in.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'ABC xyz'
    ;;
  usage-python3-minimal-os-strerror-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
import os
print(os.strerror(2))
PYCASE
    validator_assert_contains "$tmpdir/out" 'No such file'
    ;;
  usage-findutils-prune-name-batch11)
    mkdir -p "$tmpdir/tree/keep" "$tmpdir/tree/skip"
    : >"$tmpdir/tree/keep/seen.txt"
    : >"$tmpdir/tree/skip/hidden.txt"
    find "$tmpdir/tree" -name skip -prune -o -type f -printf '%f\n' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'seen.txt'
    if grep -Fq 'hidden.txt' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-tar-to-stdout-member-batch11)
    mkdir -p "$tmpdir/src"
    printf 'stdout member\n' >"$tmpdir/src/member.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/src" member.txt
    tar -xOf "$tmpdir/archive.tar" member.txt >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'stdout member'
    ;;
  usage-gzip-list-compressed-size-batch11)
    printf 'gzip listing payload\n' >"$tmpdir/plain.txt"
    gzip -k "$tmpdir/plain.txt"
    gzip -l "$tmpdir/plain.txt.gz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'compressed'
    validator_assert_contains "$tmpdir/out" 'uncompressed'
    ;;
  *)
    printf 'unknown libc6 eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
