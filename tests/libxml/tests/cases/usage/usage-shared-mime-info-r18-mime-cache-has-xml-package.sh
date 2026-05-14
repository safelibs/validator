#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r18-mime-cache-has-xml-package
# @title: shared-mime-info freedesktop.org.xml package ships an application/xml type entry
# @description: Inspects /usr/share/mime/packages/freedesktop.org.xml from the shared-mime-info package and asserts the file contains a mime-type element for application/xml — confirming the libxml-parsed source package is intact and registers the core XML MIME type.
# @timeout: 60
# @tags: usage, mime, packages, xml, r18
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

pkg=/usr/share/mime/packages/freedesktop.org.xml
validator_require_file "$pkg"

# The MIME type entry can use either single or double quotes for the attribute.
grep -Eq '<mime-type type="application/xml"|<mime-type type='\''application/xml'\''' "$pkg" || {
    echo "expected mime-type entry for application/xml" >&2
    exit 1
}

# Sanity-check this is the libxml-parseable XML package file.
head -c 5 "$pkg" | grep -q '<?xml'
