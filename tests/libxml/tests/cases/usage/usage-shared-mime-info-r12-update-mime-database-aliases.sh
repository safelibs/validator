#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r12-update-mime-database-aliases
# @title: shared-mime-info records an explicit alias entry in aliases after update-mime-database
# @description: Stages a synthetic MIME package whose mime-type declares an explicit <alias type="..."/> child, runs update-mime-database against the staging tree, and asserts the generated aliases file lists the alias mapped to the canonical custom MIME type.
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

cat >"$tmpdir/packages/validator-r12-alias.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r12alias">
    <comment>Validator synthetic aliased type</comment>
    <alias type="application/x-validator-r12-legacy"/>
    <glob pattern="*.r12alias"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
    printf 'update-mime-database failed\n' >&2
    cat "$tmpdir/install.log" >&2
    exit 1
}

validator_require_file "$tmpdir/aliases"
validator_assert_contains "$tmpdir/aliases" 'application/x-validator-r12-legacy application/x-validator-r12alias'
