#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandor-generated
# @title: ruby-vips generated bitwise or
# @description: Combines two generated images with ruby-vips bitwise OR and verifies the per-pixel bitwise union payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-bandor-generated"
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

a = gray_image(2, 1, [16, 1]).cast(:uchar)
b = gray_image(2, 1, [1, 2]).cast(:uchar)
out = (a | b).cast(:uchar)
raise "or mismatch" unless out.write_to_memory.bytes == [17, 3]
puts "or #{out.write_to_memory.bytes.join(',')}"
RUBY
