#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r17-boolean-and-self-identity
# @title: ruby-vips Image#boolean(:and, self) yields a pixel-equal image (bitwise-AND identity)
# @description: Builds an 8x8 uchar image filled with value 170 (binary 10101010), computes image.boolean(:and, image), and asserts the result has identical dimensions, format, and average pixel value 170 — exercising libvips' bitwise-AND of an image with itself as identity.
# @timeout: 60
# @tags: usage, vips, ruby, boolean, r17
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 8) + 170).cast(:uchar)
out = src.boolean(src, :and)
raise "dims=#{out.width}x#{out.height}" unless out.width == 8 && out.height == 8
raise "format=#{out.format}" unless out.format == :uchar
raise "avg=#{out.avg}" unless out.avg == 170.0
puts "boolean and self avg=#{out.avg}"
RUBY
