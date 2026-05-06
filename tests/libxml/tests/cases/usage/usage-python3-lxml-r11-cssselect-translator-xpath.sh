#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r11-cssselect-translator-xpath
# @title: cssselect.GenericTranslator emits the documented XPath translation
# @description: Asks cssselect.GenericTranslator().css_to_xpath to translate "div.foo > a" and asserts the resulting XPath uses the descendant-or-self axis with the documented class normalization predicate that selects child a elements of div.foo.
# @timeout: 60
# @tags: usage, xml, python, cssselect
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from cssselect import GenericTranslator

xp = GenericTranslator().css_to_xpath('div.foo > a')
print('xpath=' + xp)
PY

validator_assert_contains "$tmpdir/out" "descendant-or-self::div"
validator_assert_contains "$tmpdir/out" "contains(concat(' ', normalize-space(@class), ' '), ' foo ')"
validator_assert_contains "$tmpdir/out" "/a"
