#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-gamma-of-one-preserves-mean
# @title: ruby-vips Image#gamma(exponent: 1.0) leaves the image avg unchanged on a constant image
# @description: Builds a 12x12 uchar image with constant value 100, applies gamma(exponent: 1.0) which corresponds to the identity power transform, and asserts the result has the same width, height, band count, and avg as the input (avg == 100.0), confirming libvips' gamma operator is a no-op when the exponent is exactly 1.
# @timeout: 60
# @tags: usage, vips, ruby, gamma, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(12, 12) + 100).cast(:uchar)
out = src.gamma(exponent: 1.0)
raise "dims #{out.width}x#{out.height}" unless out.width == 12 && out.height == 12
raise "bands=#{out.bands}" unless out.bands == src.bands
raise "avg #{out.avg} vs #{src.avg}" unless out.avg == src.avg
puts "gamma=1.0 avg=#{out.avg}"
RUBY
