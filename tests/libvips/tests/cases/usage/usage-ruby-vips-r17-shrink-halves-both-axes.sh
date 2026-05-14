#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-shrink-halves-both-axes
# @title: ruby-vips Image#shrink(2,2) halves the width and height of the input
# @description: Builds a 32x16 uchar image, calls shrink(2,2), and asserts the output has width 16 and height 8 (each axis halved by the integer shrink factor), confirming libvips' shrink-by-integer-factor downsampling geometry.
# @timeout: 60
# @tags: usage, vips, ruby, shrink, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(32, 16) + 50).cast(:uchar)
out = src.shrink(2, 2)
raise "width=#{out.width}" unless out.width == 16
raise "height=#{out.height}" unless out.height == 8
puts "shrink #{out.width}x#{out.height}"
RUBY
