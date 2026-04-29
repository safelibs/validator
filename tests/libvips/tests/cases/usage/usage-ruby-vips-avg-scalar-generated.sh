#!/usr/bin/env bash
# @testcase: usage-ruby-vips-avg-scalar-generated
# @title: ruby-vips generated avg scalar
# @description: Computes the scalar avg of a generated image with ruby-vips and verifies the mean matches the arithmetic average of the pixel values.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-avg-scalar-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

image = gray_image(2, 1, [40, 60])
raise "avg mismatch" unless (image.avg - 50.0).abs < 0.01
puts "avg #{image.avg}"
RUBY
