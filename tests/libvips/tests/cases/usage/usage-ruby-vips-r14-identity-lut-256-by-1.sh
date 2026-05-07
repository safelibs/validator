#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-identity-lut-256-by-1
# @title: ruby-vips Image.identity returns a 256x1 single-band uchar identity LUT
# @description: Builds an 8-bit identity LUT with Vips::Image.identity and verifies the dimensions are 256x1, the band count is 1, and probing index 100 with getpoint returns 100.0, asserting libvips' identity LUT generator yields the canonical (x -> x) mapping.
# @timeout: 60
# @tags: usage, vips, ruby, identity
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
lut = Vips::Image.identity
raise "lut dims=#{lut.width}x#{lut.height}" unless lut.width == 256 && lut.height == 1
raise "lut bands=#{lut.bands}" unless lut.bands == 1
v = lut.getpoint(100, 0)
raise "lut[100]=#{v.inspect}" unless v == [100.0]
puts "identity LUT 256x1 ok"
RUBY
