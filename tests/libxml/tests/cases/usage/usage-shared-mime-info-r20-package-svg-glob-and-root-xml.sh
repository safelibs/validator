#!/usr/bin/env bash
# @testcase: usage-shared-mime-info-r20-package-svg-glob-and-root-xml
# @title: shared-mime-info package declares svg glob and the SVG root-XML namespace
# @description: Inspects /usr/share/mime/packages/freedesktop.org.xml and asserts the image/svg+xml mime-type entry declares both the *.svg glob pattern and a root-XML rule namespaced to http://www.w3.org/2000/svg — pinning the libxml-parsed shared-mime-info rules describe SVG detection.
# @timeout: 60
# @tags: usage, mime, svg, packages, r20
# @client: shared-mime-info

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

pkg=/usr/share/mime/packages/freedesktop.org.xml
validator_require_file "$pkg"

grep -Fq '<mime-type type="image/svg+xml">' "$pkg" || {
    echo "expected image/svg+xml mime-type entry" >&2
    exit 1
}

grep -Fq '<glob pattern="*.svg"' "$pkg" || {
    echo "expected *.svg glob entry" >&2
    exit 1
}

grep -Fq 'namespaceURI="http://www.w3.org/2000/svg"' "$pkg" || {
    echo "expected SVG root-XML namespaceURI rule" >&2
    exit 1
}
