#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-erode-removes-pepper-pixel
# @title: ruby-vips Image#erode with a 3x3 ones mask shrinks a single-pixel hot dot to zero
# @description: Builds a 7x7 black uchar image with a single 255 pixel at (3,3), morphs erode with a 3x3 ones structuring element, and verifies the centre pixel becomes 0, asserting libvips morphology erodes isolated pixels under a flat mask.
# @timeout: 60
# @tags: usage, vips, ruby, morphology, erode
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.black(7, 7).draw_rect(255, 3, 3, 1, 1)
raise "centre source" unless img.getpoint(3, 3) == [255.0]
mask = Vips::Image.new_from_array([[255, 255, 255], [255, 255, 255], [255, 255, 255]])
eroded = img.erode(mask)
v = eroded.getpoint(3, 3)
raise "erode centre=#{v.inspect}" unless v == [0.0]
puts "erode removed isolated pixel"
RUBY
