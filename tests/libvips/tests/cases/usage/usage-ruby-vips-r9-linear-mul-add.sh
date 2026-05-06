#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-linear-mul-add
# @title: ruby-vips linear scales then offsets pixels
# @description: Applies the linear operation a*x+b on a uniform 50-valued image and asserts the resulting pixel equals 2*50+5 = 105.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(4, 4, bands: 1) + 50
img = img.cast(:uchar)
out = img.linear([2.0], [5.0])
px = out.getpoint(2, 2)
raise "got #{px.inspect}" unless px == [105.0]
raise "max #{out.max}" unless out.max == 105.0
raise "min #{out.min}" unless out.min == 105.0
RUBY
