#!/usr/bin/env bash
# @testcase: usage-ruby-vips-deviate-zero-generated
# @title: ruby-vips generated deviate zero
# @description: Computes the deviate (standard deviation) of a uniform generated image with ruby-vips and verifies the result is essentially zero.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-deviate-zero-generated"
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

image = gray_image(3, 1, [25, 25, 25])
raise "deviate mismatch" unless image.deviate < 0.01
puts "deviate #{image.deviate}"
RUBY
