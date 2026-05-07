#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r15-subclass-default-text-plain
# @title: shared-mime-info records a sub-class-of relationship in the subclasses index
# @description: Stages a synthetic MIME package whose mime-type declares <sub-class-of type="text/plain"/>, runs update-mime-database, and asserts the produced subclasses file lists the custom type as a direct subclass of text/plain in the canonical "<child> <parent>" form.
# @timeout: 240
# @tags: usage, xml, mime, subclass
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

cat >"$tmpdir/packages/validator-r15-subclass.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-r15subclass">
    <comment>Validator r15 subclass test type</comment>
    <sub-class-of type="text/plain"/>
    <glob pattern="*.r15sub"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
    printf 'update-mime-database failed\n' >&2
    cat "$tmpdir/install.log" >&2
    exit 1
}

validator_require_file "$tmpdir/subclasses"
validator_assert_contains "$tmpdir/subclasses" 'application/x-validator-r15subclass text/plain'

# Sanity: glob pattern was also recorded.
validator_require_file "$tmpdir/globs"
validator_assert_contains "$tmpdir/globs" 'application/x-validator-r15subclass:*.r15sub'
