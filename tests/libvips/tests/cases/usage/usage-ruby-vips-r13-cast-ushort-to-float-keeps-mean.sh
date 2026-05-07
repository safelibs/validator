#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-cast-ushort-to-float-keeps-mean
# @title: ruby-vips Image#cast(:float) preserves the mean when widening from ushort
# @description: Builds a 4x4 ushort image with constant 1000, casts to :float, and verifies the cast image's format is :float and the mean is still 1000.0, asserting libvips Cast to float widens the storage without scaling the pixel values.
# @timeout: 60
# @tags: usage, vips, ruby, cast, float
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 1000).cast(:ushort)
raise "ushort format=#{img.format}" unless img.format == :ushort
out = img.cast(:float)
raise "float format=#{out.format}" unless out.format == :float
raise "float avg=#{out.avg}" unless out.avg == 1000.0
puts "cast ushort->float avg=#{out.avg}"
RUBY
