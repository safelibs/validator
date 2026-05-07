#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-dilate-grows-single-pixel
# @title: ruby-vips Image#dilate with a 3x3 ones mask grows a single hot pixel to a 3x3 block
# @description: Builds a 7x7 black image with a single 255 pixel at (3,3), morphs dilate with a 3x3 ones structuring element, and verifies the four-neighbours of the original pixel are all 255, asserting libvips morphology dilates points under a flat mask.
# @timeout: 60
# @tags: usage, vips, ruby, morphology, dilate
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.black(7, 7).draw_rect(255, 3, 3, 1, 1)
mask = Vips::Image.new_from_array([[255, 255, 255], [255, 255, 255], [255, 255, 255]])
out = img.dilate(mask)
[[2, 3], [4, 3], [3, 2], [3, 4], [3, 3]].each do |x, y|
  v = out.getpoint(x, y)
  raise "dilate (#{x},#{y})=#{v.inspect}" unless v == [255.0]
end
puts "dilate grew pixel into 3x3 block"
RUBY
