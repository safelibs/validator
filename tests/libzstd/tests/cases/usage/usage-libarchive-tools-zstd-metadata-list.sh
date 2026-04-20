#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf '#!/usr/bin/env sh\nprintf zstd-metadata\n' >"$tmpdir/in/run.sh"
chmod 755 "$tmpdir/in/run.sh"

bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" run.sh
bsdtar -tvf "$tmpdir/a.tar.zstd" >"$tmpdir/list"

grep -Fq 'run.sh' "$tmpdir/list" || {
  printf 'missing run.sh in zstd archive listing\n' >&2
  exit 1
}
grep -Eq '^-rwx' "$tmpdir/list" || {
  printf 'missing executable mode marker in zstd archive listing\n' >&2
  exit 1
}
printf 'zstd metadata list ok\n'
