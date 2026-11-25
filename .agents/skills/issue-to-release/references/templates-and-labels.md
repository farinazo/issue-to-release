# Optional Issue Templates, Labels & CI Optimization

## 1. Workflow Labels

Keeping 3 lightweight labels makes cron triage predictable:

| Label | Color | Behavior |
| :--- | :--- | :--- |
| `urgent` | `#b60205` | Triggers triage on the next scheduled check even with only 1 open issue. |
| `draft` | `#fbca04` | Excluded from cron counting and triage until you remove the label. |
| `in-progress` | `#1d76db` | Applied while an approved batch is being implemented to prevent overlap. |

Run `templates/setup-labels.sh` from your repository root (with `gh` authenticated) to create them.

## 2. CI Cost-Saving Tips (Especially Private Repos / macOS Runners)

When an agent delivers batches directly to `main`, CI builds only run once per batch instead of once per small tweak. You can save even more CI quota with three workflow additions:

1. **Skip builds for docs, templates, and skill edits (`paths-ignore`):**
   ```yaml
   on:
     push:
       branches: [main]
       paths-ignore:
         - 'README.md'
         - 'AGENTS.md'
         - 'CLAUDE.md'
         - '.agents/**'
         - '.github/ISSUE_TEMPLATE/**'
   ```
2. **Cancel superseded runs (`concurrency`):**
   ```yaml
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   ```
3. **Cache dependencies and build artifacts** with `actions/cache@v4` so CI does not rebuild heavy third-party packages from scratch on every batch.
