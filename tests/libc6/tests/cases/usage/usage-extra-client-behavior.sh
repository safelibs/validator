#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-array-expansion)
    bash -lc 'values=(alpha beta gamma); printf "%s:%d\n" "${values[1]}" "${#values[@]}"' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta:3'
    ;;
  usage-coreutils-stat-size)
    printf '1234567890' >"$tmpdir/file.txt"
    stat -c 'size=%s' "$tmpdir/file.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'size=10'
    ;;
  usage-coreutils-sha256sum)
    printf 'payload' >"$tmpdir/file.txt"
    sha256sum "$tmpdir/file.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '239f59ed'
    ;;
  usage-grep-invert-match)
    printf 'alpha\nskip\nbeta\n' | grep -v '^skip$' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    if grep -Fq 'skip' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-gawk-csv-aggregate)
    printf 'name,value\nalpha,2\nbeta,5\n' | gawk -F, 'NR > 1 {sum += $2} END {print "sum=" sum}' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sum=7'
    ;;
  usage-sed-extended-regex)
    printf 'name: alpha\n' | sed -E 's/^([^:]+): (.*)$/\1=\2/' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name=alpha'
    ;;
  usage-python3-file-io)
    python3 - <<'PY' "$tmpdir/out"
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text("python io payload\n")
print(path.read_text().strip())
PY
    validator_assert_contains "$tmpdir/out" 'python io payload'
    ;;
  usage-findutils-type-filter)
    mkdir -p "$tmpdir/root/dir"
    printf 'file\n' >"$tmpdir/root/file.txt"
    find "$tmpdir/root" -type f -printf '%f\n' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'file.txt'
    if grep -Fq 'dir' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-tar-gzip-archive)
    mkdir -p "$tmpdir/src" "$tmpdir/outdir"
    printf 'tar gzip payload\n' >"$tmpdir/src/file.txt"
    tar -C "$tmpdir/src" -czf "$tmpdir/archive.tar.gz" file.txt
    tar -C "$tmpdir/outdir" -xzf "$tmpdir/archive.tar.gz"
    validator_assert_contains "$tmpdir/outdir/file.txt" 'tar gzip payload'
    ;;
  usage-gzip-test-integrity)
    printf 'gzip integrity payload\n' >"$tmpdir/plain.txt"
    gzip -c "$tmpdir/plain.txt" >"$tmpdir/plain.txt.gz"
    gzip -tv "$tmpdir/plain.txt.gz" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'OK'
    ;;
  usage-bash-substring-expansion)
    bash -lc 'text=validator; printf "%s\n" "${text:1:4}"' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alid'
    ;;
  usage-coreutils-paste-columns)
    printf 'alpha\nbeta\n' >"$tmpdir/left.txt"
    printf '1\n2\n' >"$tmpdir/right.txt"
    paste -d ':' "$tmpdir/left.txt" "$tmpdir/right.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha:1'
    ;;
  usage-coreutils-tr-uppercase)
    printf 'mixed Case\n' | tr '[:lower:]' '[:upper:]' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'MIXED CASE'
    ;;
  usage-coreutils-uniq-count)
    printf 'alpha\nalpha\nbeta\n' | uniq -c >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2 alpha'
    ;;
  usage-grep-count-match)
    printf 'alpha\nbeta\nalpha\n' | grep -c '^alpha$' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-gawk-assoc-array)
    printf 'red\nblue\nred\n' | gawk '{count[$1]++} END {print "red=" count["red"]}' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'red=2'
    ;;
  usage-sed-delete-blank-lines)
    printf 'alpha\n\nbeta\n' | sed '/^$/d' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    if grep -Eq '^$' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-python3-pathlib-runtime)
    python3 - "$tmpdir" >"$tmpdir/out" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
path = root / "alpha.txt"
path.write_text("alpha payload\n")
print(path.name)
print(path.read_text().strip())
PY
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    validator_assert_contains "$tmpdir/out" 'alpha payload'
    ;;
  usage-findutils-maxdepth)
    mkdir -p "$tmpdir/root/child/grand"
    printf 'top\n' >"$tmpdir/root/top.txt"
    printf 'nested\n' >"$tmpdir/root/child/nested.txt"
    find "$tmpdir/root" -maxdepth 1 -type f -printf '%f\n' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'top.txt'
    if grep -Fq 'nested.txt' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-tar-list-archive)
    mkdir -p "$tmpdir/src"
    printf 'alpha\n' >"$tmpdir/src/alpha.txt"
    printf 'beta\n' >"$tmpdir/src/beta.txt"
    tar -C "$tmpdir/src" -cf "$tmpdir/archive.tar" alpha.txt beta.txt
    tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha.txt'
    validator_assert_contains "$tmpdir/out" 'beta.txt'
    ;;
  *)
    printf 'unknown libc6 extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
