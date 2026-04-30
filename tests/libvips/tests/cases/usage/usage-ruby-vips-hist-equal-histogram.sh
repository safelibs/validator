#!/usr/bin/env bash
# @testcase: usage-ruby-vips-hist-equal-histogram
# @title: ruby-vips histogram equalisation
# @description: Builds a low-contrast synthetic image, applies Vips::Image#hist_equal, and verifies the equalised image keeps shape and bands while spreading pixel values to a wider range than the input.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Low contrast 16x16 image: pixel value = 100 + (x % 4). All values live in
# [100, 103]; hist_equal should spread these across a wider range.
rows = Array.new(16) { |y| Array.new(16) { |x| 100 + (x % 4) } }
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 16 && src.height == 16
raise "src bands" unless src.bands == 1

src_min = src.min
src_max = src.max
src_span = src_max - src_min
raise "src span #{src_span}" unless src_span <= 3.0

out = src.hist_equal
raise "hist_equal dims" unless out.width == 16 && out.height == 16
raise "hist_equal bands" unless out.bands == 1

out_min = out.min
out_max = out.max
out_span = out_max - out_min
raise "hist_equal did not spread: span=#{out_span}" unless out_span > src_span * 4.0

out_path = File.join(tmpdir, "hist_equal.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "hist_equal src_span=#{src_span} out_span=#{out_span}"
RUBY

file "$tmpdir/hist_equal.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/hist_equal.png")" >&2; exit 1; }
