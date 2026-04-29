#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rot90-sample-png
# @title: ruby-vips rotate sample PNG
# @description: Rotates a PNG fixture by 90 degrees with ruby-vips and verifies swapped dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-rot90-sample-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.png")
image = Vips::Image.new_from_file(path)
out = image.rot90
raise "unexpected rotation" unless out.width == image.height && out.height == image.width
puts "rot90 #{out.width}x#{out.height}"
RUBY
