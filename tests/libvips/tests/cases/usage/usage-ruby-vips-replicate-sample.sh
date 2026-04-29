#!/usr/bin/env bash
# @testcase: usage-ruby-vips-replicate-sample
# @title: ruby-vips replicate sample
# @description: Replicates a PNG fixture with ruby-vips and verifies the output dimensions double.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-replicate-sample"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

path = File.join(sample_root, "test/test-suite/images/sample.png")
image = Vips::Image.new_from_file(path)
out = image.replicate(2, 2)
raise "unexpected dimensions" unless out.width == image.width * 2 && out.height == image.height * 2
puts "replicate #{out.width}x#{out.height}"
RUBY
