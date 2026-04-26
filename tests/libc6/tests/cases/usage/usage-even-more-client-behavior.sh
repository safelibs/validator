#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-here-string)
    read -r value <<< 'here string payload'
    test "$value" = 'here string payload'
    ;;
  usage-coreutils-sort-numeric)
    printf '10\n2\n1\n' | sort -n >"$tmpdir/out"
    test "$(sed -n '1p' "$tmpdir/out")" = '1'
    test "$(sed -n '$p' "$tmpdir/out")" = '10'
    ;;
  usage-coreutils-fold-width)
    printf 'abcdefghi\n' | fold -w 3 >"$tmpdir/out"
    test "$(sed -n '1p' "$tmpdir/out")" = 'abc'
    test "$(sed -n '3p' "$tmpdir/out")" = 'ghi'
    ;;
  usage-grep-extended-regex)
    printf 'a12z\nnope\n' >"$tmpdir/input.txt"
    grep -E 'a[0-9]+z' "$tmpdir/input.txt" >"$tmpdir/out"
    grep -Fxq 'a12z' "$tmpdir/out"
    ;;
  usage-gawk-csv-sum)
    printf 'name,count\nalpha,3\nbeta,4\n' >"$tmpdir/input.csv"
    gawk -F, 'NR > 1 {sum += $2} END {print sum}' "$tmpdir/input.csv" >"$tmpdir/out"
    grep -Fxq '7' "$tmpdir/out"
    ;;
  usage-sed-capture-group)
    printf 'alpha-42\n' | sed -E 's/^([a-z]+)-([0-9]+)$/\2:\1/' >"$tmpdir/out"
    grep -Fxq '42:alpha' "$tmpdir/out"
    ;;
  usage-python3-csv-roundtrip)
    python3 - <<'PY' "$tmpdir/out.csv"
import csv
import sys
path = sys.argv[1]
with open(path, 'w', newline='', encoding='ascii') as handle:
    writer = csv.writer(handle)
    writer.writerow(['name', 'value'])
    writer.writerow(['alpha', '7'])
with open(path, newline='', encoding='ascii') as handle:
    rows = list(csv.reader(handle))
assert rows == [['name', 'value'], ['alpha', '7']]
print(rows[1][0], rows[1][1])
PY
    ;;
  usage-findutils-empty-files)
    mkdir -p "$tmpdir/root"
    : >"$tmpdir/root/empty.txt"
    printf 'non-empty\n' >"$tmpdir/root/full.txt"
    find "$tmpdir/root" -type f -empty >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'empty.txt'
    if grep -Fq 'full.txt' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-tar-subdir-extract)
    mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
    printf 'tar payload\n' >"$tmpdir/in/dir/sub/value.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/in" dir
    tar -xf "$tmpdir/archive.tar" -C "$tmpdir/out" dir/sub/value.txt
    validator_assert_contains "$tmpdir/out/dir/sub/value.txt" 'tar payload'
    ;;
  usage-gzip-stdin-roundtrip)
    printf 'gzip stdin payload\n' | gzip -c | gzip -dc >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'gzip stdin payload'
    ;;
  *)
    printf 'unknown libc6 even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
