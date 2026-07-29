#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
private_config="$repo_root/config/app-submission.local.env"

if [[ ! -f "$private_config" ]]; then
  echo "Missing config/app-submission.local.env." >&2
  echo "Copy config/app-submission.env.example and fill it locally." >&2
  exit 1
fi

if ! git -C "$repo_root" check-ignore -q \
  config/app-submission.local.env; then
  echo "Private submission config is not ignored by Git." >&2
  exit 1
fi

failed=0
while IFS='=' read -r variable value; do
  [[ -z "$variable" || "$variable" == \#* || -z "$value" ]] && continue

  # Short values such as a first name cause unreliable matches. Longer
  # identifying values (full names, addresses, and phone numbers) are checked.
  if (( ${#value} < 8 )); then
    continue
  fi

  while IFS= read -r -d '' candidate; do
    if LC_ALL=C grep -I -F -q -- "$value" "$repo_root/$candidate"; then
      echo "Private value from $variable found in tracked candidate: $candidate" >&2
      failed=1
    fi
  done < <(
    git -C "$repo_root" ls-files -z --cached --others --exclude-standard
  )
done < "$private_config"

if (( failed != 0 )); then
  exit 1
fi

echo "No private submission values found in tracked or unignored files."
