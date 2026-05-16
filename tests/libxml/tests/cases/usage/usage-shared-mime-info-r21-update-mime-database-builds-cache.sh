#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r21-update-mime-database-builds-cache
# @title: update-mime-database builds a mime.cache from a minimal custom packages directory
# @description: Creates an isolated MIME data dir with a single packages/custom.xml declaring a glob/comment pair, runs update-mime-database on it, and asserts the resulting mime.cache binary file is present and non-empty — pinning libxml-driven update-mime-database build on a tiny package set on Ubuntu 24.04.
# @timeout: 120
# @tags: usage, shared-mime-info, update-mime-database, cache, r21
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/mime/packages"
cat >"$tmpdir/mime/packages/custom-r21.xml" <<'XML'
<?xml version="1.0"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r21">
    <comment>Validator r21 custom type</comment>
    <glob pattern="*.vr21"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir/mime" >"$tmpdir/umd.log" 2>&1
[[ -s "$tmpdir/mime/mime.cache" ]] || {
    echo "expected non-empty mime.cache" >&2
    ls -la "$tmpdir/mime" >&2
    cat "$tmpdir/umd.log" >&2
    exit 1
}
