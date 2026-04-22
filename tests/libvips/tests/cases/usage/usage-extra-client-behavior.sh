#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

case case_id
when "usage-ruby-vips-invert-image"
  image = Vips::Image.black(4, 4, bands: 1).cast("uchar") + 10
  inverted = image.invert
  raise "unexpected average" unless inverted.avg != image.avg
  puts "invert #{inverted.avg}"
when "usage-ruby-vips-extract-band"
  image = Vips::Image.black(4, 4, bands: 3) + [1, 2, 3]
  band = image.extract_band(1)
  raise "unexpected bands" unless band.bands == 1
  puts "band #{band.avg}"
when "usage-ruby-vips-flatten-alpha"
  image = Vips::Image.black(4, 4, bands: 4) + [10, 20, 30, 128]
  flat = image.flatten(background: [255, 255, 255])
  raise "unexpected bands" unless flat.bands == 3
  puts "flatten #{flat.bands}"
when "usage-ruby-vips-write-buffer"
  image = Vips::Image.black(5, 5, bands: 3) + 64
  data = image.write_to_buffer(".png")
  raise "empty buffer" unless data.bytesize > 0
  puts "buffer #{data.bytesize}"
when "usage-ruby-vips-read-sample-png"
  path = File.join(sample_root, "test/test-suite/images/sample.png")
  image = Vips::Image.new_from_file(path)
  raise "bad dimensions" unless image.width > 0 && image.height > 0
  puts "png #{image.width}x#{image.height}"
when "usage-ruby-vips-read-sample-jpeg"
  path = File.join(sample_root, "test/test-suite/images/sample.jpg")
  image = Vips::Image.new_from_file(path)
  raise "bad dimensions" unless image.width > 0 && image.height > 0
  puts "jpeg #{image.width}x#{image.height}"
when "usage-ruby-vips-cast-uchar"
  image = (Vips::Image.black(4, 4, bands: 1) + 300).cast("uchar")
  raise "unexpected format" unless image.format.to_s == "uchar"
  puts "cast #{image.format}"
when "usage-ruby-vips-replicate-image"
  image = Vips::Image.black(3, 2, bands: 1)
  out = image.replicate(3, 4)
  raise "unexpected dimensions" unless out.width == 9 && out.height == 8
  puts "replicate #{out.width}x#{out.height}"
when "usage-ruby-vips-threshold-image"
  image = Vips::Image.black(4, 4, bands: 1) + 80
  mask = image > 40
  raise "empty mask" unless mask.avg > 0
  puts "threshold #{mask.avg}"
when "usage-ruby-vips-jpeg-buffer"
  image = Vips::Image.black(8, 8, bands: 3) + 128
  data = image.write_to_buffer(".jpg")
  raise "empty jpeg" unless data.bytesize > 0
  puts "jpeg-buffer #{data.bytesize}"
else
  raise "unknown libvips extra usage case: #{case_id}"
end
RUBY
