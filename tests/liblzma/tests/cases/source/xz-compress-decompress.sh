#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'xz payload\n' >"$tmpdir/plain"; xz -c "$tmpdir/plain" >"$tmpdir/plain.xz"; xz -dc "$tmpdir/plain.xz" >"$tmpdir/out"; cmp "$tmpdir/plain" "$tmpdir/out"; xz --list "$tmpdir/plain.xz"
