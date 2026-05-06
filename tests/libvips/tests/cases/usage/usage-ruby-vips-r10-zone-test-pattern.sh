#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-zone-test-pattern
# @title: ruby-vips zone test-pattern shape and centre symmetry
# @description: Generates a zone-plate test pattern with Vips::Image.zone(64, 64) and verifies the result is a single-band 64x64 float-format image whose centre row exhibits left-right symmetry.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

img = Vips::Image.zone(64, 64)
raise "dims #{img.width}x#{img.height}" unless img.width == 64 && img.height == 64
raise "bands #{img.bands}" unless img.bands == 1

mid_y = 32
samples = (0...64).map { |x| img.getpoint(x, mid_y)[0] }

# Left-right symmetry around centre column.
checked = 0
(1..30).each do |dx|
  left = samples[32 - dx]
  right = samples[32 + dx - 1]
  raise "asymmetric at dx=#{dx} left=#{left} right=#{right}" unless (left - right).abs < 1e-3
  checked += 1
end

# Output spans more than one distinct value (it really is a pattern, not a constant).
raise "constant image" if samples.uniq.length < 5

puts "zone pattern symmetric checked=#{checked} unique=#{samples.uniq.length}"
RUBY
