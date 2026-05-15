#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-bandbool-or-yields-bitwise-or
# @title: ruby-vips Image#bandor on a three-band image returns the bitwise OR across bands
# @description: Builds a 4x4 RGB image where the three bands carry constant values 1, 2, and 4 respectively, calls bandbool(:or) (equivalent to bandor) to fold the three bands with bitwise OR, asserts the result has one band and the same width and height as the source, and asserts every output pixel equals 1|2|4 = 7 (avg=7, min=7, max=7), confirming libvips' bitwise band-fold reduction.
# @timeout: 60
# @tags: usage, vips, ruby, bandbool, or, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
b1 = (Vips::Image.black(4, 4) + 1).cast(:uchar)
b2 = (Vips::Image.black(4, 4) + 2).cast(:uchar)
b3 = (Vips::Image.black(4, 4) + 4).cast(:uchar)
src = b1.bandjoin([b2, b3])
out = src.bandbool(:or)
raise "bands=#{out.bands}" unless out.bands == 1
raise "dims" unless out.width == 4 && out.height == 4
raise "avg=#{out.avg}" unless out.avg == 7
raise "min=#{out.min}" unless out.min == 7
raise "max=#{out.max}" unless out.max == 7
puts "bandor avg=#{out.avg}"
RUBY
