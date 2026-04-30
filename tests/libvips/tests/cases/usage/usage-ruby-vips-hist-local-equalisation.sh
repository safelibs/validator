#!/usr/bin/env bash
# @testcase: usage-ruby-vips-hist-local-equalisation
# @title: ruby-vips hist_local local histogram equalisation
# @description: Builds a 32x32 low-contrast image, applies Vips::Image#hist_local with a 7x7 window, and verifies the result preserves dimensions and band count while spreading pixel values across a wider range than the input.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 32x32 low-contrast image with values in [100, 105].
rows = Array.new(32) { |y| Array.new(32) { |x| 100 + ((x + y) % 6) } }
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 32 && src.height == 32
raise "src bands" unless src.bands == 1

src_span = src.max - src.min
raise "src span #{src_span}" unless src_span <= 5.0

# 7x7 window for local equalisation.
out = src.hist_local(7, 7)
raise "out dims" unless out.width == 32 && out.height == 32
raise "out bands" unless out.bands == 1

out_span = out.max - out.min
# Local equalisation should expand the per-window contrast significantly
# beyond the input's narrow range.
raise "hist_local did not widen range: out_span=#{out_span}" unless out_span > src_span * 5.0

out_path = File.join(tmpdir, "hist_local.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 32 && reload.height == 32
puts "hist_local src_span=#{src_span} out_span=#{out_span}"
RUBY

file "$tmpdir/hist_local.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/hist_local.png")" >&2; exit 1; }
