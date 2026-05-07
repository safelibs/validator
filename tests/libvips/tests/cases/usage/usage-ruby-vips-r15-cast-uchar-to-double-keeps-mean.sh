#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-cast-uchar-to-double-keeps-mean
# @title: ruby-vips Image#cast(:double) widens uchar to double without scaling
# @description: Builds a 3x3 single-band uchar image with constant 70, casts to :double, and verifies the cast image's format is :double and the mean is still 70.0, asserting libvips Cast widens the storage from uchar to double without scaling the pixel values.
# @timeout: 60
# @tags: usage, vips, ruby, cast, double
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(3, 3) + 70).cast(:uchar)
raise "uchar format=#{img.format}" unless img.format == :uchar
out = img.cast(:double)
raise "double format=#{out.format}" unless out.format == :double
raise "double avg=#{out.avg}" unless out.avg == 70.0
puts "cast uchar->double avg=#{out.avg}"
RUBY
