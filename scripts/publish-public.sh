#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TARGET_REPO="safelibs/validator"
TARGET_HTTPS="https://github.com/${TARGET_REPO}.git"
TARGET_SSH="git@github.com:${TARGET_REPO}.git"

require_local_gh_auth() {
  if ! gh auth status >/dev/null 2>&1; then
    echo "No GH_TOKEN or SAFELIBS_REPO_TOKEN is set, and gh is not authenticated for repo creation or private tag inspection." >&2
    exit 1
  fi
}

read_repo_field() {
  local field=$1
  local payload=$2
  REPO_JSON="$payload" python3 - "$field" <<'PY'
import json
import os
import sys

field = sys.argv[1]
payload = json.loads(os.environ["REPO_JSON"])
print(payload[field])
PY
}

if [[ -n "${GH_TOKEN:-}" ]]; then
  export GH_TOKEN
  remote_url="https://x-access-token:${GH_TOKEN}@github.com/${TARGET_REPO}.git"
elif [[ -n "${SAFELIBS_REPO_TOKEN:-}" ]]; then
  export GH_TOKEN="$SAFELIBS_REPO_TOKEN"
  remote_url="https://x-access-token:${GH_TOKEN}@github.com/${TARGET_REPO}.git"
else
  require_local_gh_auth
  remote_url="$TARGET_SSH"
fi

cd "$ROOT_DIR"

python3 tools/inventory.py --config repositories.yml --check-remote-tags

repo_json=$(
  gh repo view safelibs/validator --json visibility,nameWithOwner,url 2>/dev/null || true
)
if [[ -z "$repo_json" ]]; then
  gh repo create safelibs/validator --public --confirm
  repo_json=$(gh repo view safelibs/validator --json visibility,nameWithOwner,url)
fi

name_with_owner=$(read_repo_field nameWithOwner "$repo_json")
visibility=$(read_repo_field visibility "$repo_json")
repo_url=$(read_repo_field url "$repo_json")

if [[ "$name_with_owner" != "$TARGET_REPO" ]]; then
  echo "Unexpected repository target: $name_with_owner" >&2
  exit 1
fi

if [[ "${visibility^^}" != "PUBLIC" ]]; then
  echo "Existing $TARGET_REPO repository is not public: $visibility" >&2
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$remote_url"
else
  git remote add origin "$remote_url"
fi

git push origin HEAD:main

origin_url=$(git remote get-url origin)
if [[ "$origin_url" != *"${TARGET_REPO}"* ]]; then
  echo "origin does not point at ${TARGET_REPO}: ${origin_url}" >&2
  exit 1
fi

remote_line=$(git ls-remote --heads origin main)
if [[ -z "$remote_line" ]]; then
  echo "origin does not advertise refs/heads/main after push" >&2
  exit 1
fi

remote_sha=${remote_line%%$'\t'*}
local_sha=$(git rev-parse HEAD)
if [[ "$remote_sha" != "$local_sha" ]]; then
  echo "origin main does not match local HEAD: ${remote_sha} != ${local_sha}" >&2
  exit 1
fi

printf 'Published %s (%s) to %s\n' "$TARGET_REPO" "$visibility" "$repo_url"
