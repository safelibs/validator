#!/usr/bin/env bash
# @testcase: usage-ruby-vips-autorot-no-orientation
# @title: ruby-vips autorot identity on unrotated image
# @description: Loads a synthetic image written via Vips::Image#write_to_file and verifies that Vips::Image#autorot is a no-op when the image carries no EXIF orientation tag, preserving width, height, and exact pixel values.
# @timeout: 120
# @tags: usage, ruby, image, exif
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Asymmetric 6x4 single-band image so any rotation would be visible in dims.
src = Vips::Image.new_from_array([
  [10, 20, 30, 40, 50, 60],
  [11, 21, 31, 41, 51, 61],
  [12, 22, 32, 42, 52, 62],
  [13, 23, 33, 43, 53, 63],
])
raise "src dims" unless src.width == 6 && src.height == 4

png_path = File.join(tmpdir, "src.png")
src.cast(:uchar).write_to_file(png_path)

reload = Vips::Image.new_from_file(png_path)
rotated = reload.autorot

raise "autorot dims #{rotated.width}x#{rotated.height}" unless rotated.width == 6 && rotated.height == 4
raise "autorot bands" unless rotated.bands == reload.bands

# Pixels should match exactly since autorot was a no-op.
[[0, 0], [5, 0], [0, 3], [5, 3]].each do |x, y|
  before = reload.getpoint(x, y)
  after = rotated.getpoint(x, y)
  raise "pixel mismatch #{x},#{y}: before=#{before} after=#{after}" unless before == after
end

puts "autorot identity #{rotated.width}x#{rotated.height}"
RUBY
