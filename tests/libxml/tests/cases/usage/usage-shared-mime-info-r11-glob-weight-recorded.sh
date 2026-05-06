#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r11-glob-weight-recorded
# @title: shared-mime-info preserves explicit glob weight column in globs2
# @description: Stages a synthetic MIME package whose <glob> declares an explicit weight="80" attribute, runs update-mime-database, and asserts the generated globs2 file lists the weight in the leading numeric column for the custom MIME type.
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

cat >"$tmpdir/packages/validator-weighted.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r11weighted">
    <comment>Validator synthetic weighted glob type</comment>
    <glob pattern="*.r11weighted" weight="80"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
    printf 'update-mime-database failed\n' >&2
    cat "$tmpdir/install.log" >&2
    exit 1
}

validator_require_file "$tmpdir/globs2"
validator_assert_contains "$tmpdir/globs2" '80:application/x-validator-r11weighted:*.r11weighted'
