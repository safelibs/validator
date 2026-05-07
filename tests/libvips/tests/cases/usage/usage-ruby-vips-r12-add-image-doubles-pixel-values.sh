#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-add-image-doubles-pixel-values
# @title: ruby-vips Image#+ on identical images doubles each pixel value
# @description: Builds a 4x4 constant-50 uchar image and verifies (img + img).avg returns 100.0 within 1e-9, asserting libvips elementwise addition behaves as expected when the operands are identical buffers and the format is promoted to short to hold the sum without overflow.
# @timeout: 60
# @tags: usage, vips, ruby, arithmetic, add
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 50).cast(:uchar)
out = img + img
v = out.avg
raise "add-image avg=#{v}" unless (v - 100.0).abs < 1e-9
puts "img + img avg=#{v}"
RUBY
