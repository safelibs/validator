#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-best-compress-roundtrip)
    printf 'best compression payload\n' >"$tmpdir/input.txt"
    bzip2 -9k "$tmpdir/input.txt"
    bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'best compression payload'
    ;;
  usage-bzip2-fast-compress-roundtrip)
    printf 'fast compression payload\n' >"$tmpdir/input.txt"
    bzip2 -1k "$tmpdir/input.txt"
    bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'fast compression payload'
    ;;
  usage-bzip2-stdout-keep-input)
    printf 'stdout keep payload\n' >"$tmpdir/input.txt"
    bzip2 -kc "$tmpdir/input.txt" >"$tmpdir/out.bz2"
    validator_assert_contains "$tmpdir/input.txt" 'stdout keep payload'
    bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'stdout keep payload'
    ;;
  usage-bunzip2-stdout-roundtrip)
    printf 'bunzip stdout payload\n' >"$tmpdir/input.txt"
    bzip2 -zk "$tmpdir/input.txt"
    bunzip2 -c "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'bunzip stdout payload'
    ;;
  usage-bzip2-test-verbose)
    printf 'verbose payload\n' >"$tmpdir/input.txt"
    bzip2 -zk "$tmpdir/input.txt"
    bzip2 -tvv "$tmpdir/input.txt.bz2" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-bzgrep-line-number)
    cat >"$tmpdir/input.txt" <<'EOF'
alpha
beta
gamma
EOF
    bzip2 -zk "$tmpdir/input.txt"
    bzgrep -n 'beta' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2:beta'
    ;;
  usage-bzgrep-count-lines)
    cat >"$tmpdir/input.txt" <<'EOF'
beta
alpha
beta
EOF
    bzip2 -zk "$tmpdir/input.txt"
    bzgrep -c 'beta' "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-bzcat-two-files)
    printf 'first\n' >"$tmpdir/one.txt"
    printf 'second\n' >"$tmpdir/two.txt"
    bzip2 -zk "$tmpdir/one.txt"
    bzip2 -zk "$tmpdir/two.txt"
    bzcat "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'first'
    validator_assert_contains "$tmpdir/out" 'second'
    ;;
  usage-bzip2-stdin-roundtrip)
    printf 'stdin payload\n' | bzip2 -c >"$tmpdir/out.bz2"
    bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'stdin payload'
    ;;
  usage-bzip2-empty-file-roundtrip)
    : >"$tmpdir/empty.txt"
    bzip2 -zk "$tmpdir/empty.txt"
    bunzip2 -c "$tmpdir/empty.txt.bz2" >"$tmpdir/out"
    test "$(wc -c <"$tmpdir/out")" -eq 0
    ;;
  *)
    printf 'unknown libbz2 expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
