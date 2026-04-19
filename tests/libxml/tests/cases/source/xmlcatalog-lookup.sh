#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<!ELEMENT root EMPTY>\n' >"$tmpdir/demo.dtd"; cat >"$tmpdir/catalog.xml" <<XML
<?xml version="1.0"?><catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog"><public publicId="-//Example//DTD Demo//EN" uri="$tmpdir/demo.dtd"/></catalog>
XML
xmlcatalog "$tmpdir/catalog.xml" '-//Example//DTD Demo//EN' | tee "$tmpdir/lookup"; grep demo.dtd "$tmpdir/lookup"
