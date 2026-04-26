#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bzip2-multi-file-compress)
    printf 'alpha\n' >"$tmpdir/alpha.txt"
    printf 'beta\n' >"$tmpdir/beta.txt"
    bzip2 "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
    validator_require_file "$tmpdir/alpha.txt.bz2"
    validator_require_file "$tmpdir/beta.txt.bz2"
    ;;
  usage-bzip2-multi-file-decompress)
    printf 'alpha\n' >"$tmpdir/alpha.txt"
    printf 'beta\n' >"$tmpdir/beta.txt"
    bzip2 "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
    bunzip2 "$tmpdir/alpha.txt.bz2" "$tmpdir/beta.txt.bz2"
    validator_assert_contains "$tmpdir/alpha.txt" 'alpha'
    validator_assert_contains "$tmpdir/beta.txt" 'beta'
    ;;
  usage-bzip2-keep-multi-file-compress)
    printf 'alpha\n' >"$tmpdir/alpha.txt"
    printf 'beta\n' >"$tmpdir/beta.txt"
    bzip2 -k "$tmpdir/alpha.txt" "$tmpdir/beta.txt"
    validator_require_file "$tmpdir/alpha.txt"
    validator_require_file "$tmpdir/beta.txt"
    validator_require_file "$tmpdir/alpha.txt.bz2"
    validator_require_file "$tmpdir/beta.txt.bz2"
    ;;
  usage-bzip2-space-filename-compress)
    printf 'space payload\n' >"$tmpdir/space name.txt"
    bzip2 "$tmpdir/space name.txt"
    validator_require_file "$tmpdir/space name.txt.bz2"
    ;;
  usage-bzip2-space-filename-decompress)
    printf 'space payload\n' >"$tmpdir/space name.txt"
    bzip2 "$tmpdir/space name.txt"
    bunzip2 "$tmpdir/space name.txt.bz2"
    validator_assert_contains "$tmpdir/space name.txt" 'space payload'
    ;;
  usage-bunzip2-test-alias)
    printf 'alias payload\n' >"$tmpdir/input.txt"
    bzip2 "$tmpdir/input.txt"
    bunzip2 -t "$tmpdir/input.txt.bz2"
    ;;
  usage-bzgrep-word-regexp)
    cat >"$tmpdir/input.txt" <<'EOF'
alpha beta
gamma
EOF
    bzip2 -k "$tmpdir/input.txt"
    bzgrep -w beta "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha beta'
    ;;
  usage-bzgrep-only-matching)
    cat >"$tmpdir/input.txt" <<'EOF'
alpha beta gamma
EOF
    bzip2 -k "$tmpdir/input.txt"
    bzgrep -o beta "$tmpdir/input.txt.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-bzcat-concatenated-streams)
    printf 'first\n' >"$tmpdir/first.txt"
    printf 'second\n' >"$tmpdir/second.txt"
    bzip2 -c "$tmpdir/first.txt" >"$tmpdir/first.bz2"
    bzip2 -c "$tmpdir/second.txt" >"$tmpdir/second.bz2"
    cat "$tmpdir/first.bz2" "$tmpdir/second.bz2" >"$tmpdir/combined.bz2"
    bzcat "$tmpdir/combined.bz2" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'first'
    validator_assert_contains "$tmpdir/out" 'second'
    ;;
  usage-bzip2-stdout-space-file)
    printf 'space stdout payload\n' >"$tmpdir/space name.txt"
    bzip2 -c "$tmpdir/space name.txt" >"$tmpdir/out.bz2"
    bunzip2 -c "$tmpdir/out.bz2" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'space stdout payload'
    ;;
  *)
    printf 'unknown libbz2 further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
