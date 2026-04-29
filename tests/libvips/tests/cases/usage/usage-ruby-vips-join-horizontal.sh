#!/usr/bin/env bash
# @testcase: usage-ruby-vips-join-horizontal
# @title: ruby-vips horizontal join
# @description: Exercises ruby-vips horizontal join through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-join-horizontal"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes[0]
end

left = gray_image(2, 1, [10, 20])
right = gray_image(2, 1, [30, 40])
out = left.join(right, :horizontal)
raise 'join mismatch' unless out.width == 4 && gray_pixel(out, 3, 0) == 40
puts "join #{out.width}"
RUBY
