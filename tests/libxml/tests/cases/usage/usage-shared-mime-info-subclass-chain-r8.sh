#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-subclass-chain-r8
# @title: shared-mime-info subclass chain registration
# @description: Stages a synthetic MIME package that declares a custom application/x-validator-config+xml type as a sub-class-of application/xml, runs update-mime-database to parse it through libxml2, and verifies the rebuilt subclasses file records the parent relationship and that types/globs2 also list the new entry.
# @timeout: 180
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

cat >"$tmpdir/packages/validator-config.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-config+xml">
    <comment>Validator synthetic config XML type</comment>
    <sub-class-of type="application/xml"/>
    <glob pattern="*.vconf"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/log" 2>&1 || {
  printf 'update-mime-database failed\n' >&2
  cat "$tmpdir/log" >&2
  exit 1
}

validator_require_file "$tmpdir/subclasses"
validator_require_file "$tmpdir/types"
validator_require_file "$tmpdir/globs2"

validator_assert_contains "$tmpdir/types" 'application/x-validator-config+xml'
validator_assert_contains "$tmpdir/globs2" ':application/x-validator-config+xml:*.vconf'
validator_assert_contains "$tmpdir/subclasses" 'application/x-validator-config+xml application/xml'

parent=$(awk '$1=="application/x-validator-config+xml" {print $2; exit}' "$tmpdir/subclasses")
[[ "$parent" == "application/xml" ]] || {
  printf 'expected parent application/xml, got %s\n' "$parent" >&2
  cat "$tmpdir/subclasses" >&2
  exit 1
}
