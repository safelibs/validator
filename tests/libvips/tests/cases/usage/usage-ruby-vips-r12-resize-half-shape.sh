#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-resize-half-shape
# @title: ruby-vips Image#resize 0.5 halves both dimensions of a 40x20 image to 20x10
# @description: Builds a 40x20 constant uchar image and verifies Image#resize(0.5).width == 20 and .height == 10, asserting libvips' resize honours the scalar scale factor in both axes.
# @timeout: 60
# @tags: usage, vips, ruby, resize
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(40, 20) + 128).cast(:uchar)
out = img.resize(0.5)
raise "resize dims=#{out.width}x#{out.height}" unless out.width == 20 && out.height == 10
puts "resize 0.5 -> #{out.width}x#{out.height}"
RUBY
