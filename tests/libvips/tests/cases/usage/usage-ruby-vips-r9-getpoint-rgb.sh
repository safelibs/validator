#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-getpoint-rgb
# @title: ruby-vips getpoint reports RGB triple
# @description: Builds a uniform RGB image with known component values and asserts getpoint returns those exact values at multiple coordinates.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(8, 8, bands: 3) + [11, 22, 33]
img = img.cast(:uchar)
[[0, 0], [3, 5], [7, 7]].each do |x, y|
  px = img.getpoint(x, y)
  raise "got #{px.inspect} at #{x},#{y}" unless px == [11.0, 22.0, 33.0]
end
RUBY
