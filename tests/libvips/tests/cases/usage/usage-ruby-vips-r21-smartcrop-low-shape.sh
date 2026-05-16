#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-smartcrop-low-shape
# @title: ruby-vips Image#smartcrop with interesting :low returns the requested crop dimensions
# @description: Builds a 32x24 single-band uchar image with constant value 60, calls smartcrop(16, 12, interesting: :low), and asserts the result is exactly 16x12 with the same band count as the source, exercising libvips' attention-model-independent crop sizing.
# @timeout: 60
# @tags: usage, vips, ruby, smartcrop, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(32, 24) + 60).cast(:uchar)
out = src.smartcrop(16, 12, interesting: :low)
raise "w=#{out.width}" unless out.width == 16
raise "h=#{out.height}" unless out.height == 12
raise "bands=#{out.bands}" unless out.bands == src.bands
puts "smartcrop low #{out.width}x#{out.height}"
RUBY
