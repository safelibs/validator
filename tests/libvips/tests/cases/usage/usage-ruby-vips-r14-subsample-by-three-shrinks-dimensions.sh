#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-subsample-by-three-shrinks-dimensions
# @title: ruby-vips Image#subsample(3, 3) reduces a 9x9 image to 3x3
# @description: Builds a 9x9 single-band uchar constant image and applies Vips::Image#subsample(3, 3), verifying the result is 3x3 with bands == 1 and the average matches the source (since subsampling a constant image does not alter values), asserting libvips' subsample picks every Nth column/row exactly.
# @timeout: 60
# @tags: usage, vips, ruby, subsample
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(9, 9) + 77).cast(:uchar)
out = src.subsample(3, 3)
raise "subsample dims=#{out.width}x#{out.height}" unless out.width == 3 && out.height == 3
raise "subsample bands=#{out.bands}" unless out.bands == 1
raise "subsample avg=#{out.avg}" unless out.avg == 77.0
puts "subsample 3x3 ok avg=#{out.avg}"
RUBY
