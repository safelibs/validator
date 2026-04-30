#!/usr/bin/env bash
# @testcase: usage-ruby-vips-invert-roundtrip-identity
# @title: ruby-vips invert twice equals identity
# @description: Inverts a synthetic uchar image twice via Vips::Image#invert and asserts the result equals the original pixel-for-pixel by checking the max of the absolute difference is zero.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Asymmetric ramp across an 8x2 image so the average is not 127.5; that
# guarantees a single invert visibly changes the mean (255 - mean != mean).
pixels = Array.new(16) { |i| (i * 7) % 200 }
src = Vips::Image.new_from_memory(pixels.pack('C*'), 8, 2, 1, :uchar)
raise "src dims" unless src.width == 8 && src.height == 2

once = src.invert
twice = once.invert.cast(:uchar)
raise "twice format" unless twice.format.to_s == "uchar"
raise "twice dims" unless twice.width == 8 && twice.height == 2

# Ensure the single invert actually changed something.
raise "single invert no-op" unless (once.cast(:uchar).avg - src.avg).abs > 1e-6

# The double invert must equal the source exactly.
diff = (twice - src).abs
raise "max diff #{diff.max} not zero" unless diff.max == 0.0
raise "avg matches" unless (twice.avg - src.avg).abs < 1e-9

out_path = File.join(tmpdir, "roundtrip.png")
twice.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "invert roundtrip ok max_diff=#{diff.max}"
RUBY

file "$tmpdir/roundtrip.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/roundtrip.png")" >&2; exit 1; }
