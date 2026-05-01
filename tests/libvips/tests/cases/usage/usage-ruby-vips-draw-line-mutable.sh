#!/usr/bin/env bash
# @testcase: usage-ruby-vips-draw-line-mutable
# @title: ruby-vips draw_line on a mutable image
# @description: Mutates a black canvas via Vips::MutableImage#draw_line! to paint a horizontal stroke and verifies pixels along the stroke carry the painted ink while pixels off the stroke remain at the background value.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

base = (Vips::Image.black(20, 20) + 0).cast(:uchar)
painted = base.mutate do |m|
  m.draw_line!([180], 2, 10, 17, 10)
end

raise "dims" unless painted.width == 20 && painted.height == 20
raise "bands" unless painted.bands == 1

[2, 5, 10, 15, 17].each do |x|
  v = painted.getpoint(x, 10)
  raise "on-line (#{x},10)=#{v.inspect}" unless v == [180.0]
end

# Off-line pixels remain background.
[[0, 0], [10, 0], [10, 9], [10, 11], [19, 19]].each do |x, y|
  v = painted.getpoint(x, y)
  raise "off-line (#{x},#{y})=#{v.inspect}" unless v == [0.0]
end

out_path = File.join(tmpdir, "line.png")
painted.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "draw_line ok"
RUBY

file "$tmpdir/line.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/line.png")" >&2; exit 1; }
