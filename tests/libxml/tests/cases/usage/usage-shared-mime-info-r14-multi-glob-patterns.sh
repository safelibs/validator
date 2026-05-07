#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r14-multi-glob-patterns
# @title: shared-mime-info records every glob pattern declared on a custom MIME type
# @description: Stages a synthetic MIME package whose mime-type declares two distinct glob patterns, runs update-mime-database against the staging tree, and asserts the generated globs file lists both patterns mapped to the same canonical MIME type so multi-glob declarations are preserved.
# @timeout: 240
# @tags: usage, xml, mime
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

mime_packages_src=/usr/share/mime/packages
validator_require_dir "$mime_packages_src"
validator_require_file "$mime_packages_src/freedesktop.org.xml"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/packages"
cp "$mime_packages_src"/*.xml "$tmpdir/packages/"

cat >"$tmpdir/packages/validator-r14-multi-glob.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r14multi">
    <comment>Validator r14 multi-glob type</comment>
    <glob pattern="*.r14primary"/>
    <glob pattern="*.r14alt"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
    printf 'update-mime-database failed\n' >&2
    cat "$tmpdir/install.log" >&2
    exit 1
}

validator_require_file "$tmpdir/globs"
validator_assert_contains "$tmpdir/globs" 'application/x-validator-r14multi:*.r14primary'
validator_assert_contains "$tmpdir/globs" 'application/x-validator-r14multi:*.r14alt'
