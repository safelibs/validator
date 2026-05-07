#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-rot90-applied-four-times-equals-identity
# @title: ruby-vips Image#rot90 chained four times restores the original dimensions and mean
# @description: Builds an 8x8 single-band uchar constant image, applies Vips::Image#rot90 four times in succession, and verifies the result has the same 8x8 dimensions, bands == 1, and the same mean as the source, asserting libvips' 90-degree rotation composes to identity over four applications.
# @timeout: 60
# @tags: usage, vips, ruby, rot90, identity
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 50).cast(:uchar)
out = src.rot90.rot90.rot90.rot90
raise "rot90x4 dims=#{out.width}x#{out.height}" unless out.width == 8 && out.height == 8
raise "rot90x4 bands=#{out.bands}" unless out.bands == 1
raise "rot90x4 avg=#{out.avg}" unless out.avg == 50.0
puts "rot90x4 identity ok dims=#{out.width}x#{out.height} avg=#{out.avg}"
RUBY
