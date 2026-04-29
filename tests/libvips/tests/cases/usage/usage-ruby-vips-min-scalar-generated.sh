#!/usr/bin/env bash
# @testcase: usage-ruby-vips-min-scalar-generated
# @title: ruby-vips generated min scalar
# @description: Computes the scalar min of a generated three-pixel image with ruby-vips and verifies it returns the smallest pixel value.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-min-scalar-generated"
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

image = gray_image(3, 1, [50, 5, 200])
raise "min mismatch" unless image.min == 5.0
puts "min #{image.min}"
RUBY
