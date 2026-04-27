#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-bash-parameter-trim)
    bash >"$tmpdir/out" <<'SH'
value='alpha.beta.txt'
printf '%s\n' "${value%.txt}"
SH
    validator_assert_contains "$tmpdir/out" 'alpha.beta'
    ;;
  usage-bash-array-length)
    bash >"$tmpdir/out" <<'SH'
items=(one two three)
printf '%s\n' "${#items[@]}"
SH
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-coreutils-wc-bytes)
    printf 'abcd' >"$tmpdir/input.txt"
    wc -c <"$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '4'
    ;;
  usage-coreutils-sort-unique)
    cat >"$tmpdir/input.txt" <<'EOF'
beta
alpha
beta
EOF
    sort -u "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-coreutils-cut-field)
    cat >"$tmpdir/input.csv" <<'EOF'
name,score
alpha,42
EOF
    cut -d, -f2 "$tmpdir/input.csv" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'score'
    validator_assert_contains "$tmpdir/out" '42'
    ;;
  usage-grep-line-number)
    cat >"$tmpdir/input.txt" <<'EOF'
alpha
beta
gamma
EOF
    grep -n 'beta' "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2:beta'
    ;;
  usage-gawk-sum-column)
    cat >"$tmpdir/input.csv" <<'EOF'
alpha,5
beta,7
gamma,9
EOF
    gawk -F, '{sum += $2} END {print sum}' "$tmpdir/input.csv" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '21'
    ;;
  usage-sed-global-replace-all)
    printf 'foo one foo two\n' >"$tmpdir/input.txt"
    sed 's/foo/bar/g' "$tmpdir/input.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'bar one bar two'
    ;;
  usage-coreutils-basename-suffix)
    mkdir -p "$tmpdir/path"
    : >"$tmpdir/path/archive.tar.gz"
    basename "$tmpdir/path/archive.tar.gz" .tar.gz >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'archive'
    ;;
  usage-tar-create-list)
    mkdir -p "$tmpdir/tree/sub"
    printf 'tar payload\n' >"$tmpdir/tree/sub/file.txt"
    tar -cf "$tmpdir/archive.tar" -C "$tmpdir/tree" .
    tar -tf "$tmpdir/archive.tar" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" './sub/file.txt'
    ;;
  *)
    printf 'unknown libc6 expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
