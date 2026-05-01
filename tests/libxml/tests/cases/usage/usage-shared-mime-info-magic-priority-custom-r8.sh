#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-magic-priority-custom-r8
# @title: shared-mime-info custom magic priority emitted to magic file
# @description: Stages a synthetic MIME package that declares a custom magic match with a non-default priority and a literal byte signature, runs update-mime-database to parse it through libxml2, and verifies the rebuilt magic file emits the priority header for the new type and that types/globs2 also reflect the registration.
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
    <comment>Validator synthetic magic-bearing type</comment>
    <magic priority="60">
      <match type="string" value="VALMAGIC1" offset="0"/>
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

validator_assert_contains "$tmpdir/types" 'application/x-validator-magic'
validator_assert_contains "$tmpdir/globs2" ':application/x-validator-magic:*.vmag'
# Priority header in magic is "[<priority>:<mime>]" on its own line.
validator_assert_contains "$tmpdir/magic" '[60:application/x-validator-magic]'

# Confirm at least one magic block carries our exact priority.
blocks=$(grep -c '^\[60:application/x-validator-magic\]$' "$tmpdir/magic" || true)
[[ "$blocks" -ge 1 ]] || {
  printf 'expected priority-60 block for synthetic type, got %s\n' "$blocks" >&2
  exit 1
}
