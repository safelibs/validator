#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf '#!/usr/bin/env sh\nprintf xz-metadata\n' >"$tmpdir/in/run.sh"
chmod 755 "$tmpdir/in/run.sh"

bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" run.sh
bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list"

grep -Fq 'run.sh' "$tmpdir/list" || {
  printf 'missing run.sh in xz archive listing\n' >&2
  exit 1
}
grep -Eq '^-rwx' "$tmpdir/list" || {
  printf 'missing executable mode marker in xz archive listing\n' >&2
  exit 1
}
printf 'xz metadata list ok\n'
