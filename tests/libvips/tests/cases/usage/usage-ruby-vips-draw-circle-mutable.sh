#!/usr/bin/env bash
# @testcase: usage-ruby-vips-draw-circle-mutable
# @title: ruby-vips draw_circle on a mutable image
# @description: Mutates an image in place via Vips::MutableImage#draw_circle and verifies the centre and an off-circle pixel reflect the painted ink and untouched background respectively.
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
  m.draw_circle!([200], 10, 10, 4, fill: true)
end

raise "dims" unless painted.width == 20 && painted.height == 20
raise "bands" unless painted.bands == 1

centre = painted.getpoint(10, 10)
raise "centre #{centre.inspect}" unless centre == [200.0]
edge_in = painted.getpoint(10 + 3, 10)
raise "edge_in #{edge_in.inspect}" unless edge_in == [200.0]
corner = painted.getpoint(0, 0)
raise "corner #{corner.inspect}" unless corner == [0.0]

out_path = File.join(tmpdir, "circle.png")
painted.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)

reload = Vips::Image.new_from_file(out_path)
raise "reload dims" unless reload.width == 20 && reload.height == 20
puts "draw_circle ok centre=#{centre}"
RUBY

file "$tmpdir/circle.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/circle.png")" >&2; exit 1; }
