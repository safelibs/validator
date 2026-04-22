#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-script-exec)
    bash -lc 'printf "shell=%d\n" "$((6 * 7))"' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'shell=42'
    ;;
  usage-coreutils-sort)
    printf 'b\na\nc\n' | sort >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" $'a\nb\nc'
    ;;
  usage-grep-regex)
    printf 'alpha\nbeta\ngamma\n' | grep -E '^(alpha|gamma)$' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-gawk-field-sum)
    printf 'a 2\nb 5\n' | gawk '{sum += $2} END {print "sum=" sum}' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sum=7'
    ;;
  usage-sed-transform)
    printf 'name=old\n' | sed 's/old/new/' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name=new'
    ;;
  usage-python3-runtime)
    python3 - <<'PY' >"$tmpdir/out"
print("answer=%d" % (6 * 7))
PY
    validator_assert_contains "$tmpdir/out" 'answer=42'
    ;;
  usage-findutils-find)
    mkdir -p "$tmpdir/root/sub"
    printf 'payload\n' >"$tmpdir/root/sub/target.txt"
    find "$tmpdir/root" -name target.txt -print >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'target.txt'
    ;;
  usage-tar-roundtrip)
    mkdir -p "$tmpdir/src" "$tmpdir/outdir"
    printf 'tar payload\n' >"$tmpdir/src/file.txt"
    tar -C "$tmpdir/src" -cf "$tmpdir/archive.tar" file.txt
    tar -C "$tmpdir/outdir" -xf "$tmpdir/archive.tar"
    validator_assert_contains "$tmpdir/outdir/file.txt" 'tar payload'
    ;;
  usage-gzip-roundtrip)
    printf 'gzip payload\n' >"$tmpdir/plain.txt"
    gzip -c "$tmpdir/plain.txt" >"$tmpdir/plain.txt.gz"
    gzip -dc "$tmpdir/plain.txt.gz" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'gzip payload'
    ;;
  usage-coreutils-date)
    date -u -d '@0' '+year=%Y' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'year=1970'
    ;;
  *)
    printf 'unknown libc6 usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
