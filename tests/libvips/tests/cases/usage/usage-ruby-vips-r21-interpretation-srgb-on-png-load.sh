#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-interpretation-srgb-on-png-load
# @title: ruby-vips Image#interpretation is :srgb for a 3-band uchar PNG round-trip
# @description: Builds a 4x4 three-band uchar image, encodes it as PNG via write_to_buffer, decodes back via new_from_buffer, casts to the srgb colourspace, and asserts the resulting interpretation is :srgb, exercising libvips' colourspace tagging plumbing.
# @timeout: 60
# @tags: usage, vips, ruby, interpretation, srgb, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.black(4, 4).bandjoin([Vips::Image.black(4, 4), Vips::Image.black(4, 4)])
src = (src + 50).cast(:uchar)
bytes = src.write_to_buffer('.png')
out = Vips::Image.new_from_buffer(bytes, '').colourspace(:srgb)
raise "bands=#{out.bands}" unless out.bands == 3
raise "interp=#{out.interpretation}" unless out.interpretation == :srgb
puts "interpretation=#{out.interpretation}"
RUBY
