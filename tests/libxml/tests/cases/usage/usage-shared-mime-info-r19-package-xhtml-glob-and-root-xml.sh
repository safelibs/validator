#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r19-package-xhtml-glob-and-root-xml
# @title: shared-mime-info package declares xhtml glob and root-XML namespace for application/xhtml+xml
# @description: Inspects /usr/share/mime/packages/freedesktop.org.xml and asserts the application/xhtml+xml mime-type entry declares both the *.xhtml glob and a root-XML element scoped to the XHTML namespace — confirming the libxml-parsed shared-mime-info rules describe XHTML detection.
# @timeout: 60
# @tags: usage, mime, xhtml, packages, r19
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

pkg=/usr/share/mime/packages/freedesktop.org.xml
validator_require_file "$pkg"

grep -Fq '<mime-type type="application/xhtml+xml">' "$pkg" || {
    echo "expected application/xhtml+xml mime-type entry" >&2
    exit 1
}

# Glob for *.xhtml extension must be present.
grep -Fq '<glob pattern="*.xhtml"' "$pkg" || {
    echo "expected *.xhtml glob entry" >&2
    exit 1
}

# Root-XML rule must scope on the XHTML namespace URI.
grep -Fq 'namespaceURI="http://www.w3.org/1999/xhtml"' "$pkg" || {
    echo "expected XHTML root-XML namespaceURI rule" >&2
    exit 1
}
