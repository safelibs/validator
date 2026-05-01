#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-alias-resolution-r7
# @title: shared-mime-info alias entry registration
# @description: Stages a synthetic MIME package that declares application/x-validator-canonical with an alias element pointing at application/x-validator-old, runs update-mime-database to parse it through libxml2, and verifies the rebuilt aliases file maps the alias name to the canonical type and that both type names are listed in the types file.
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

cat >"$tmpdir/packages/validator-alias.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-canonical">
    <comment>Validator canonical synthetic type</comment>
    <glob pattern="*.vcan"/>
    <alias type="application/x-validator-old"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/log" 2>&1 || {
  printf 'update-mime-database failed\n' >&2
  cat "$tmpdir/log" >&2
  exit 1
}

validator_require_file "$tmpdir/aliases"
validator_require_file "$tmpdir/types"

validator_assert_contains "$tmpdir/types" 'application/x-validator-canonical'
validator_assert_contains "$tmpdir/aliases" 'application/x-validator-old application/x-validator-canonical'

resolved=$(awk '$1=="application/x-validator-old" {print $2; exit}' "$tmpdir/aliases")
[[ "$resolved" == "application/x-validator-canonical" ]] || {
  printf 'expected alias to resolve to canonical, got %s\n' "$resolved" >&2
  cat "$tmpdir/aliases" >&2
  exit 1
}

printf 'alias-resolved=%s\n' "$resolved"
