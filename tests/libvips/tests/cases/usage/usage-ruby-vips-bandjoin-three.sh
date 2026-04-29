#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandjoin-three
# @title: ruby-vips bandjoin three
# @description: Combines three single-band images into one multi-band image with ruby-vips.
# @timeout: 180
# @tags: usage, image, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-bandjoin-three"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" "$VALIDATOR_SAMPLE_ROOT" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]
sample_root = ARGV[2]

a = Vips::Image.black(4, 4, bands: 1) + 1
b = Vips::Image.black(4, 4, bands: 1) + 2
c = Vips::Image.black(4, 4, bands: 1) + 3
out = a.bandjoin(b).bandjoin(c)
raise "unexpected bands" unless out.bands == 3
puts "bands #{out.bands}"
RUBY
