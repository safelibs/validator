#!/usr/bin/env bash
# @testcase: multi-stream-behavior
# @title: xz multi stream behavior
# @description: Concatenates xz streams and verifies decompression preserves both payloads.
# @timeout: 120
# @tags: cli, stream

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\n' >"$tmpdir/a"; printf 'beta\n' >"$tmpdir/b"; xz -c "$tmpdir/a" >"$tmpdir/a.xz"; xz -c "$tmpdir/b" >"$tmpdir/b.xz"; cat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/two.xz"; xz -dc "$tmpdir/two.xz" | tee "$tmpdir/out"; cmp <(printf 'alpha\nbeta\n') "$tmpdir/out"
