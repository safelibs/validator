#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${PROFILE:-release}"

"$ROOT/safe/scripts/build-original-baseline.sh"
if [[ "$PROFILE" == "release" ]]; then
  cargo build --manifest-path "$ROOT/safe/Cargo.toml" --release --lib --bins
else
  cargo build --manifest-path "$ROOT/safe/Cargo.toml" --lib --bins
fi
"$ROOT/safe/scripts/install-staging.sh" "$ROOT/safe/target/stage"
