#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandjoin-constant
# @title: ruby-vips bandjoin constant
# @description: Exercises ruby-vips bandjoin constant through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-bandjoin-constant"
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

image = gray_image(1, 1, [12])
out = image.bandjoin(200)
raise 'bandjoin mismatch' unless out.bands == 2
puts "bands #{out.bands}"
RUBY
