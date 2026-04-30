#!/usr/bin/env bash
# @testcase: usage-ruby-vips-hist-norm-stretch
# @title: ruby-vips hist_norm stretch to full range
# @description: Builds a low-contrast 8-bit image, applies Vips::Image#hist_norm, and verifies that the normalised image has the same dimensions and band count as the input while spanning a noticeably wider value range than the source.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 16x16 source restricted to a narrow [120, 130] band.
rows = Array.new(16) { |y| Array.new(16) { |x| 120 + ((x + y) % 11) } }
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 16 && src.height == 16
raise "src bands" unless src.bands == 1

src_lo = src.min
src_hi = src.max
src_span = src_hi - src_lo
raise "src too wide #{src_span}" unless src_span <= 10.0

out = src.hist_norm
raise "out dims" unless out.width == 16 && out.height == 16
raise "out bands" unless out.bands == 1

out_lo = out.min
out_hi = out.max
out_span = out_hi - out_lo
# hist_norm equalises the histogram and must produce a strictly wider value
# range than the narrow input band.
raise "hist_norm did not widen range: src_span=#{src_span} out_span=#{out_span}" unless out_span > src_span

out_path = File.join(tmpdir, "hist_norm.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 16 && reload.height == 16
puts "hist_norm src_span=#{src_span} out_span=#{out_span}"
RUBY

file "$tmpdir/hist_norm.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/hist_norm.png")" >&2; exit 1; }
