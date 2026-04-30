#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-derived-xml-type-install
# @title: shared-mime-info derived XML MIME type install and uninstall
# @description: Stages a synthetic MIME package that defines an application/xml-derived type with a custom .vex extension, runs update-mime-database to install it, verifies the derived type is registered in globs2 and types and that XMLnamespaces records its root namespace, then removes the package, rebuilds, and verifies the synthetic type is no longer registered, exercising libxml2 SAX parsing through both install and uninstall code paths.
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

cat >"$tmpdir/packages/validator-vex.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-validator-vex+xml">
    <comment>Validator synthetic vex document</comment>
    <sub-class-of type="application/xml"/>
    <glob pattern="*.vex"/>
    <root-XML namespaceURI="urn:validator:vex" localName="vex"/>
  </mime-type>
</mime-info>
XML

# Install: rebuild the database and check the new type is registered.
update-mime-database "$tmpdir" >"$tmpdir/install.log" 2>&1 || {
  printf 'update-mime-database install failed\n' >&2
  cat "$tmpdir/install.log" >&2
  exit 1
}

validator_require_file "$tmpdir/mime.cache"
validator_require_file "$tmpdir/globs2"
validator_require_file "$tmpdir/types"
validator_require_file "$tmpdir/XMLnamespaces"

validator_assert_contains "$tmpdir/types"  'application/x-validator-vex+xml'
validator_assert_contains "$tmpdir/globs2" ':application/x-validator-vex+xml:*.vex'
validator_assert_contains "$tmpdir/XMLnamespaces" 'urn:validator:vex'
validator_assert_contains "$tmpdir/XMLnamespaces" 'application/x-validator-vex+xml'

vex_mime=$(awk -F: '$3=="*.vex" {print $2; exit}' "$tmpdir/globs2")
[[ "$vex_mime" == "application/x-validator-vex+xml" ]] || {
  printf 'expected application/x-validator-vex+xml for *.vex, got %s\n' "$vex_mime" >&2
  exit 1
}

# Uninstall: remove the synthetic package and rebuild.
rm "$tmpdir/packages/validator-vex.xml"
update-mime-database "$tmpdir" >"$tmpdir/uninstall.log" 2>&1 || {
  printf 'update-mime-database uninstall failed\n' >&2
  cat "$tmpdir/uninstall.log" >&2
  exit 1
}

if grep -F 'application/x-validator-vex+xml' "$tmpdir/types" >/dev/null; then
  printf 'synthetic type still present in types after uninstall\n' >&2
  exit 1
fi
if grep -F ':*.vex' "$tmpdir/globs2" >/dev/null; then
  printf 'synthetic *.vex glob still present after uninstall\n' >&2
  exit 1
fi
if grep -F 'urn:validator:vex' "$tmpdir/XMLnamespaces" >/dev/null; then
  printf 'synthetic XML namespace still present after uninstall\n' >&2
  exit 1
fi

printf 'install-mime=%s\n' "$vex_mime"
printf 'uninstalled=ok\n'
