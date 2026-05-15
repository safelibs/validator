#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-replicate-doubles-height
# @title: ruby-vips Image#replicate(1, 3) preserves width and triples height
# @description: Builds a 7x5 uchar image, calls replicate(1, 3) to tile 1-wide by 3-tall, asserts the result has width 7 (unchanged), height 15 (3x), and the same band count as the input, and asserts the mean is preserved (constant input -> constant output), confirming libvips' vertical replicate geometry.
# @timeout: 60
# @tags: usage, vips, ruby, replicate, vertical, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(7, 5) + 80).cast(:uchar)
out = src.replicate(1, 3)
raise "width=#{out.width}" unless out.width == 7
raise "height=#{out.height}" unless out.height == 15
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg=#{out.avg}" unless out.avg == src.avg
puts "replicate #{out.width}x#{out.height}"
RUBY
