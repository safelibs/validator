#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-gaussblur-preserves-mean
# @title: ruby-vips Image#gaussblur preserves the mean of a uniform image within 1.0
# @description: Builds an 8x8 constant-100 uchar image, applies Image#gaussblur(2.0), and verifies the output's mean stays within 1.0 of the original 100, asserting libvips Gaussian blur is mean-preserving on a uniform input.
# @timeout: 60
# @tags: usage, vips, ruby, gaussblur, filter
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(8, 8) + 100).cast(:uchar)
blurred = img.gaussblur(2.0)
diff = (blurred.avg - 100.0).abs
raise "gaussblur mean drift=#{diff}" unless diff < 1.0
puts "gaussblur avg=#{blurred.avg}"
RUBY
