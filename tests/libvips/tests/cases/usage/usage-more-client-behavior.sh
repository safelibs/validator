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
when "usage-ruby-vips-fliphor-sample"
  path = File.join(sample_root, "test/test-suite/images/sample.png")
  image = Vips::Image.new_from_file(path)
  out = image.fliphor
  raise "unexpected dimensions" unless out.width == image.width && out.height == image.height
  puts "fliphor #{out.width}x#{out.height}"
when "usage-ruby-vips-flipver-sample"
  path = File.join(sample_root, "test/test-suite/images/sample.png")
  image = Vips::Image.new_from_file(path)
  out = image.flipver
  raise "unexpected dimensions" unless out.width == image.width && out.height == image.height
  puts "flipver #{out.width}x#{out.height}"
when "usage-ruby-vips-rot180-sample"
  path = File.join(sample_root, "test/test-suite/images/sample.jpg")
  image = Vips::Image.new_from_file(path)
  out = image.rot180
  raise "unexpected dimensions" unless out.width == image.width && out.height == image.height
  puts "rot180 #{out.width}x#{out.height}"
when "usage-ruby-vips-insert-generated"
  base = Vips::Image.black(6, 6, bands: 3) + [10, 20, 30]
  patch = Vips::Image.black(2, 2, bands: 3) + [200, 50, 10]
  out = base.insert(patch, 2, 2)
  raise "unexpected dimensions" unless out.width == 6 && out.height == 6
  puts "insert #{out.width}x#{out.height}"
when "usage-ruby-vips-read-buffer-png"
  image = Vips::Image.black(5, 4, bands: 3) + 90
  data = image.write_to_buffer(".png")
  reload = Vips::Image.new_from_buffer(data, "")
  raise "unexpected dimensions" unless reload.width == 5 && reload.height == 4
  puts "buffer #{reload.width}x#{reload.height}"
when "usage-ruby-vips-extract-area-generated"
  image = Vips::Image.black(8, 6, bands: 3) + 30
  out = image.extract_area(1, 2, 3, 2)
  raise "unexpected crop" unless out.width == 3 && out.height == 2
  puts "extract #{out.width}x#{out.height}"
when "usage-ruby-vips-bandmean-generated"
  image = Vips::Image.black(4, 4, bands: 3) + [10, 20, 30]
  out = image.bandmean
  raise "unexpected bands" unless out.bands == 1
  puts "bandmean #{out.avg}"
when "usage-ruby-vips-embed-generated"
  image = Vips::Image.black(3, 2, bands: 3) + 120
  out = image.embed(1, 2, 6, 5)
  raise "unexpected dimensions" unless out.width == 6 && out.height == 5
  puts "embed #{out.width}x#{out.height}"
when "usage-ruby-vips-flatten-background"
  image = Vips::Image.black(4, 4, bands: 4) + [10, 20, 30, 128]
  out = image.flatten(background: [255, 255, 255])
  raise "unexpected bands" unless out.bands == 3
  puts "flatten #{out.bands}"
when "usage-ruby-vips-png-file-output"
  image = Vips::Image.black(7, 5, bands: 3) + 180
  path = File.join(tmpdir, "out.png")
  image.write_to_file(path)
  reload = Vips::Image.new_from_file(path)
  raise "unexpected png output" unless File.size(path) > 0 && reload.width == 7 && reload.height == 5
  puts "png #{File.size(path)}"
else
  raise "unknown libvips additional usage case: #{case_id}"
end
RUBY
