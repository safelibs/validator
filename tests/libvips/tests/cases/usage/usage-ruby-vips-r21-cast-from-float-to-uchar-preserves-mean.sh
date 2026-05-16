#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-cast-from-float-to-uchar-preserves-mean
# @title: ruby-vips Image#cast from float to uchar preserves the mean for in-range constant pixels
# @description: Builds an 8x8 image with constant value 75 in float format, casts it to uchar, and asserts the resulting format is :uchar and the avg equals 75 (no saturation), validating libvips' format conversion when no pixel exceeds [0, 255].
# @timeout: 60
# @tags: usage, vips, ruby, cast, format, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 75).cast(:float)
raise "src_fmt=#{src.format}" unless src.format == :float
out = src.cast(:uchar)
raise "fmt=#{out.format}" unless out.format == :uchar
raise "avg=#{out.avg}" unless out.avg == 75
puts "cast float->uchar avg=#{out.avg}"
RUBY
