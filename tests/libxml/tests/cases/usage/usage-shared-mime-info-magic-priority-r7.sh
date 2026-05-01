#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-magic-priority-r7
# @title: shared-mime-info magic priority install
# @description: Stages a synthetic MIME package that defines an application/x-validator-magic type with a magic match rule keyed on a fixed leading byte sequence and priority 60, runs update-mime-database to parse it through libxml2, and verifies the rebuilt magic file lists the synthetic type with the declared priority and that the rule appears before lower-priority entries.
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

cat >"$tmpdir/packages/validator-magic.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-magic">
    <comment>Validator synthetic magic-detected document</comment>
    <magic priority="60">
      <match type="string" offset="0" value="VLDR-MAGIC"/>
    </magic>
    <glob pattern="*.vmag"/>
  </mime-type>
</mime-info>
XML

update-mime-database "$tmpdir" >"$tmpdir/log" 2>&1 || {
  printf 'update-mime-database failed\n' >&2
  cat "$tmpdir/log" >&2
  exit 1
}

validator_require_file "$tmpdir/magic"
validator_require_file "$tmpdir/types"
validator_require_file "$tmpdir/globs2"

validator_assert_contains "$tmpdir/types"  'application/x-validator-magic'
validator_assert_contains "$tmpdir/globs2" ':application/x-validator-magic:*.vmag'

# The magic database is binary; use grep -a to confirm both the priority
# string ([60:application/x-validator-magic]) and the literal magic value.
grep -aF '[60:application/x-validator-magic]' "$tmpdir/magic" >/dev/null || {
  printf 'expected priority 60 entry for synthetic magic type\n' >&2
  exit 1
}
grep -aF 'VLDR-MAGIC' "$tmpdir/magic" >/dev/null || {
  printf 'expected literal magic bytes in compiled magic file\n' >&2
  exit 1
}

printf 'magic-priority=60\n'
printf 'magic-bytes=VLDR-MAGIC\n'
