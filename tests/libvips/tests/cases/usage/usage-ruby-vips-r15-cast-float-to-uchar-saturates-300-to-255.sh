#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-cast-float-to-uchar-saturates-300-to-255
# @title: ruby-vips Image#cast(:uchar) clamps an out-of-range float pixel of 300 down to 255
# @description: Builds a 4x4 single-band float image with constant 300 (well outside the uchar [0,255] range), casts to :uchar, and verifies the cast image's format is :uchar and the mean is 255.0, asserting libvips' Cast saturates over-range float values to the uchar maximum rather than wrapping or NaN-ing.
# @timeout: 60
# @tags: usage, vips, ruby, cast, saturation
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
big = (Vips::Image.black(4, 4) + 300).cast(:float)
raise "src format=#{big.format}" unless big.format == :float
clamped = big.cast(:uchar)
raise "clamped format=#{clamped.format}" unless clamped.format == :uchar
raise "clamped avg=#{clamped.avg}" unless clamped.avg == 255.0
puts "cast saturation ok avg=#{clamped.avg}"
RUBY
