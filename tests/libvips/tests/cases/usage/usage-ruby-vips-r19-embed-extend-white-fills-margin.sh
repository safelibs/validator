#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-embed-extend-white-fills-margin
# @title: ruby-vips Image#embed with extend :white pads the canvas margin with 255 (uchar white)
# @description: Builds a 4x4 uchar image with constant value 80, calls embed(2, 2, 8, 8, extend: :white) to place the source at (2,2) on an 8x8 canvas, asserts the result is 8x8 with the same band count as the source, asserts the maximum pixel value is 255 (the white margin) and the minimum is 80 (the inset content), confirming libvips' :white extend mode fills the surrounding margin with 255 for uchar input.
# @timeout: 60
# @tags: usage, vips, ruby, embed, white, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(4, 4) + 80).cast(:uchar)
out = src.embed(2, 2, 8, 8, extend: :white)
raise "dims" unless out.width == 8 && out.height == 8
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "max=#{out.max}" unless out.max == 255
raise "min=#{out.min}" unless out.min == 80
puts "embed white max=#{out.max} min=#{out.min}"
RUBY
