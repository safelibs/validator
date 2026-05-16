#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-extract-area-zero-zero-corner-pixel
# @title: ruby-vips Image#extract_area 1x1 at (0,0) yields a single-pixel image matching the source corner
# @description: Builds a 5x5 uchar image with constant value 123, calls extract_area(0, 0, 1, 1), and asserts the resulting image has width 1, height 1, and getpoint(0, 0)[0] equals 123, validating libvips' boundary extraction at the origin.
# @timeout: 60
# @tags: usage, vips, ruby, extract-area, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(5, 5) + 123).cast(:uchar)
cell = src.extract_area(0, 0, 1, 1)
raise "width=#{cell.width}" unless cell.width == 1
raise "height=#{cell.height}" unless cell.height == 1
val = cell.getpoint(0, 0)
raise "val=#{val.inspect}" unless val[0] == 123
puts "extract_area corner=#{val[0]}"
RUBY
