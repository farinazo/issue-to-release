#!/usr/bin/env bash
set -euo pipefail

gh label create "urgent" --color "b60205" --description "Trigger immediate triage without waiting for batch minimum" --force
gh label create "draft" --color "fbca04" --description "Work-in-progress idea — skipped by scheduled triage" --force
gh label create "in-progress" --color "1d76db" --description "Approved batch currently being implemented" --force

echo "Labels created/updated: urgent, draft, in-progress"
