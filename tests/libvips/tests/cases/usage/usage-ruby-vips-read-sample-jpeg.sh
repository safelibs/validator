#!/usr/bin/env bash
# @testcase: usage-ruby-vips-read-sample-jpeg
# @title: ruby-vips reads sample JPEG
# @description: Loads a checked-in JPEG fixture with ruby-vips and verifies dimensions.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-read-sample-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.jpg")
image = Vips::Image.new_from_file(path)
raise "bad dimensions" unless image.width > 0 && image.height > 0
puts "jpeg #{image.width}x#{image.height}"
RUBY
