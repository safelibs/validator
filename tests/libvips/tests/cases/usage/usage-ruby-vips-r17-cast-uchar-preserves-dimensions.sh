#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-cast-uchar-preserves-dimensions
# @title: ruby-vips Image#cast(:uchar) preserves width, height, and band count
# @description: Builds a 17x11 single-band black image, casts it to :uchar, and asserts the result has identical width (17), height (11), bands (1), and format :uchar, confirming libvips' format-cast operation leaves geometry untouched.
# @timeout: 60
# @tags: usage, vips, ruby, cast, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.black(17, 11)
out = src.cast(:uchar)
raise "width=#{out.width}" unless out.width == 17
raise "height=#{out.height}" unless out.height == 11
raise "bands=#{out.bands}" unless out.bands == 1
raise "format=#{out.format}" unless out.format == :uchar
puts "cast uchar #{out.width}x#{out.height}x#{out.bands}"
RUBY
