#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r13-comment-localized
# @title: shared-mime-info preserves localized xml:lang comments through update-mime-database
# @description: Stages a synthetic MIME package whose mime-type carries both a default-locale comment and a localized xml:lang="fr" comment, runs update-mime-database against the staging tree, and asserts the generated XML output for the custom MIME type retains both the default and the French comment text.
# @timeout: 240
# @tags: usage, xml, mime, localization
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

cat >"$tmpdir/packages/validator-r13-localized.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r13localized">
    <comment>Validator r13 localized type</comment>
    <comment xml:lang="fr">Type localisé r13 du validateur</comment>
    <glob pattern="*.r13localized"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
    printf 'update-mime-database failed\n' >&2
    cat "$tmpdir/install.log" >&2
    exit 1
}

# update-mime-database splits each MIME type into application/x-...xml under
# the staging root. Locate the produced file and verify both comments survive.
generated="$tmpdir/application/x-validator-r13localized.xml"
validator_require_file "$generated"
validator_assert_contains "$generated" 'Validator r13 localized type'
validator_assert_contains "$generated" 'xml:lang="fr"'
validator_assert_contains "$generated" 'Type localisé r13 du validateur'
