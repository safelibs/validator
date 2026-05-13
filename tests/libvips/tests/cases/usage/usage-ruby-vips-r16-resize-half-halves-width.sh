#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-resize-half-halves-width
# @title: ruby-vips Image#resize 0.5 halves both width and height of a uchar source
# @description: Builds a 32x24 single-band uchar image with constant value 40, calls Image#resize(0.5), and asserts the result has width 16, height 12, and bands 1, exercising libvips' resize operator with a fractional factor.
# @timeout: 60
# @tags: usage, vips, ruby, resize
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(32, 24) + 40).cast(:uchar)
out = src.resize(0.5)
raise "dims=#{out.width}x#{out.height}" unless out.width == 16 && out.height == 12
raise "bands=#{out.bands}" unless out.bands == 1
puts "resize half dims=#{out.width}x#{out.height}"
RUBY
