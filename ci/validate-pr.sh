#!/usr/bin/env bash
set -euo pipefail

event_name="$GITHUB_EVENT_NAME"
event_file="$GITHUB_EVENT_PATH"
if [[ "$event_name" == "pull_request" ]]; then
  pr_title="$(jq -r '.pull_request.title // ""' "$event_file")"
  pr_body="$(jq -r '.pull_request.body // ""' "$event_file")"
  [[ -n "${pr_title//[[:space:]]/}" ]] || { echo "PR title is required." >&2; exit 1; }
  [[ -n "${pr_body//[[:space:]]/}" ]] || { echo "PR description is required." >&2; exit 1; }
fi
if [[ "$event_name" == "pull_request" ]]; then
  base_ref="${GITHUB_BASE_REF:?GITHUB_BASE_REF is required for pull requests}"
  git fetch --no-tags origin "$base_ref"
  changed_files="$(git diff --name-only "origin/$base_ref...HEAD")"
else
  previous_commit="$(git rev-parse HEAD^ 2>/dev/null || true)"
  if [[ -n "$previous_commit" ]]; then
    changed_files="$(git diff --name-only "$previous_commit" HEAD)"
  else
    changed_files="$(git ls-files)"
  fi
fi
database_change=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in database/migrations/*|database/seeders/*|database/sql/*|database/*.sql) database_change=1 ;; esac
  case "$file" in
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|secrets/*|*/secrets/*) echo "Forbidden secret file: $file" >&2; exit 1 ;;
    deployment/*|deploy/*|ansible/*|docker-compose.prod.yml|docker-compose.production.yml) echo "Unexpected deployment file: $file" >&2; exit 1 ;;
  esac
done <<< "$changed_files"
if [[ "$database_change" -eq 1 && "$event_name" == "pull_request" ]] && ! grep -Eiq '^database[ _-]*change[[:space:]]*:[[:space:]]*yes[[:space:]]*$' <<< "$pr_body"; then
  echo "Database change declaration is required." >&2; exit 1
fi
echo "A1-A2 validation passed."
printf '%s\n' "$changed_files"
