#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-extract-area-returns-requested-rect
# @title: ruby-vips Image#extract_area returns an image with the requested width and height
# @description: Builds a 20x12 uchar image, calls extract_area(3, 2, 7, 5) to pull a 7x5 sub-rectangle starting at (3, 2), and asserts the result has width 7, height 5, and the same band count as the input, confirming libvips' rectangular extraction preserves geometry exactly.
# @timeout: 60
# @tags: usage, vips, ruby, extract_area, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(20, 12) + 50).cast(:uchar)
out = src.extract_area(3, 2, 7, 5)
raise "width=#{out.width}"   unless out.width == 7
raise "height=#{out.height}" unless out.height == 5
raise "bands=#{out.bands}"   unless out.bands == src.bands
puts "extract_area #{out.width}x#{out.height}"
RUBY
