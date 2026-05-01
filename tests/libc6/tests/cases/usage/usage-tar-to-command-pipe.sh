#!/usr/bin/env bash
# @testcase: usage-tar-to-command-pipe
# @title: tar --to-command streams members to a child process
# @description: Extracts an archive with tar --to-command running a small bash filter that captures member contents and the TAR_FILENAME environment variable, verifying tar invokes the helper once per member through libc fork/exec.
# @timeout: 180
# @tags: usage, tar, libc
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-to-command-pipe"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha-payload\n' >"$tmpdir/src/alpha.txt"
printf 'beta-payload\n'  >"$tmpdir/src/beta.txt"

tar --sort=name -cf "$tmpdir/archive.tar" -C "$tmpdir/src" alpha.txt beta.txt

cat >"$tmpdir/sink.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=$1
{
  printf '== %s ==\n' "$TAR_FILENAME"
  cat
} >>"$out"
EOF
chmod +x "$tmpdir/sink.sh"

: >"$tmpdir/log"
tar -xf "$tmpdir/archive.tar" --to-command="$tmpdir/sink.sh $tmpdir/log"

validator_assert_contains "$tmpdir/log" '== alpha.txt =='
validator_assert_contains "$tmpdir/log" 'alpha-payload'
validator_assert_contains "$tmpdir/log" '== beta.txt =='
validator_assert_contains "$tmpdir/log" 'beta-payload'

# Two member headers indicate tar invoked the helper once per member.
header_count=$(grep -c '^== ' "$tmpdir/log")
test "$header_count" -eq 2
