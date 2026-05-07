#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-cast-uchar-to-ushort-promotes-format
# @title: ruby-vips Image#cast(:ushort) promotes the format from uchar to ushort
# @description: Builds a 4x4 uchar image with constant 100, casts to :ushort, and verifies the cast image's format is :ushort and the mean is still 100.0, asserting libvips Cast widens the storage without scaling the pixel values.
# @timeout: 60
# @tags: usage, vips, ruby, cast
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(4, 4) + 100).cast(:uchar)
raise "uchar format=#{img.format}" unless img.format == :uchar
out = img.cast(:ushort)
raise "ushort format=#{out.format}" unless out.format == :ushort
raise "ushort avg=#{out.avg}" unless out.avg == 100.0
puts "cast uchar->ushort avg=#{out.avg}"
RUBY
