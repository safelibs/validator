#!/usr/bin/env bash
# @testcase: usage-ruby-vips-read-sample-png
# @title: ruby-vips reads sample PNG
# @description: Loads a checked-in PNG fixture with ruby-vips and verifies dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-read-sample-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.png")
image = Vips::Image.new_from_file(path)
raise "bad dimensions" unless image.width > 0 && image.height > 0
puts "png #{image.width}x#{image.height}"
RUBY
