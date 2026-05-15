#!/usr/bin/env bash
# @testcase: usage-tar-r20-strip-components-removes-prefix
# @title: tar --strip-components=1 drops the top-level directory from extracted paths
# @description: Builds a tarball containing pkg/inner/file.txt, extracts it with --strip-components=1 into a fresh directory, and asserts the extracted layout has inner/file.txt at the root and no pkg/ directory - locking in libc-backed path manipulation via tar's component-stripping extraction.
# @timeout: 60
# @tags: usage, tar, strip-components, r20
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/pkg/inner"
printf 'strip-components-payload\n' >"$tmpdir/src/pkg/inner/file.txt"

tar -cf "$tmpdir/out.tar" -C "$tmpdir/src" pkg

mkdir -p "$tmpdir/extract"
tar --strip-components=1 -xf "$tmpdir/out.tar" -C "$tmpdir/extract"

validator_require_file "$tmpdir/extract/inner/file.txt"
if [[ -d "$tmpdir/extract/pkg" ]]; then
    echo 'expected pkg/ to be stripped, but it still exists' >&2
    exit 1
fi
