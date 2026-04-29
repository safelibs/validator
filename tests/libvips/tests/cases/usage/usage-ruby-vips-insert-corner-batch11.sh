#!/usr/bin/env bash
# @testcase: usage-ruby-vips-insert-corner-batch11
# @title: ruby-vips insert corner
# @description: Inserts a one-pixel patch at the lower corner with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-insert-corner-batch11"
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

def bytes(image)
  image.cast(:uchar).write_to_memory.bytes
end

base = gray_image(4, 4, Array.new(16, 10))
patch = gray_image(1, 1, [200])
out = base.insert(patch, 3, 3)
raise "insert corner" unless bytes(out.extract_area(3, 3, 1, 1)) == [200]
puts "insert"
RUBY
