#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-gaussblur-preserves-dimensions
# @title: ruby-vips Image#gaussblur(1.0) preserves the width and height of the input
# @description: Builds a 16x16 uchar image with a constant value, applies gaussblur(1.0), and asserts the output retains the 16x16 dimensions and remains single-band uchar, confirming libvips' Gaussian blur does not crop the canvas.
# @timeout: 60
# @tags: usage, vips, ruby, gaussblur, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(16, 16) + 100).cast(:uchar)
out = src.gaussblur(1.0)
raise "dims=#{out.width}x#{out.height}" unless out.width == 16 && out.height == 16
raise "bands=#{out.bands}" unless out.bands == 1
puts "gaussblur dims=#{out.width}x#{out.height}"
RUBY
