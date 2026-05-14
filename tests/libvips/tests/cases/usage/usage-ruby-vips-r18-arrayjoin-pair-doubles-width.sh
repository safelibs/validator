#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-arrayjoin-pair-doubles-width
# @title: ruby-vips Image.arrayjoin([a, b]) horizontally concatenates and doubles total width
# @description: Builds two 6x4 uchar images, calls Vips::Image.arrayjoin([a, b], across: 2) to lay them out side-by-side in a single row, and asserts the result has width 12 (2 * 6), height 4, and the same band count as the inputs, confirming libvips' arrayjoin lays out tiles in a fixed across-count grid.
# @timeout: 60
# @tags: usage, vips, ruby, arrayjoin, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
a = (Vips::Image.black(6, 4) + 12).cast(:uchar)
b = (Vips::Image.black(6, 4) + 34).cast(:uchar)
out = Vips::Image.arrayjoin([a, b], across: 2)
raise "width=#{out.width}"   unless out.width == 12
raise "height=#{out.height}" unless out.height == 4
raise "bands=#{out.bands}"   unless out.bands == a.bands
puts "arrayjoin #{out.width}x#{out.height}"
RUBY
