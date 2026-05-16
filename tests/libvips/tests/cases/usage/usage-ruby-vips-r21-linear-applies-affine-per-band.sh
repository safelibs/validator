#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-linear-applies-affine-per-band
# @title: ruby-vips Image#linear applies separate affine constants to each band
# @description: Builds a 4x4 three-band uchar image with band values 10, 20, 30, calls linear([2.0, 3.0, 1.0], [1.0, 2.0, 0.0]) to apply ax+b independently per band, asserts the result averages 113/3 (= (10*2+1 + 20*3+2 + 30*1+0)/3 = (21+62+30)/3), exercising libvips' per-band affine transform.
# @timeout: 60
# @tags: usage, vips, ruby, linear, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
b0 = (Vips::Image.black(4, 4) + 10).cast(:uchar)
b1 = (Vips::Image.black(4, 4) + 20).cast(:uchar)
b2 = (Vips::Image.black(4, 4) + 30).cast(:uchar)
src = b0.bandjoin([b1, b2])
raise "bands=#{src.bands}" unless src.bands == 3
out = src.linear([2.0, 3.0, 1.0], [1.0, 2.0, 0.0])
raise "bands=#{out.bands}" unless out.bands == 3
expected = (10*2 + 1 + 20*3 + 2 + 30*1 + 0).to_f / 3.0
raise "avg=#{out.avg} expected=#{expected}" unless (out.avg - expected).abs < 1e-6
puts "linear per_band avg=#{out.avg}"
RUBY
