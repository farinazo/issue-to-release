---
name: issue-to-release
description: >-
  Human-in-the-loop GitHub Issue triage, multi-select batching, quick plan
  approval, single-commit delivery, GitHub Actions CI monitoring with auto-fix,
  and release commentary. Supports scheduled CRON mode (minimum batch size or
  priority labels) and on-demand MANUAL mode across OpenAI Codex, Antigravity,
  and Claude Code.
---

# Issue-to-Release

Turn GitHub Issues into batched, reviewed, CI-verified releases without touching a single file before explicit user approval.

## Prerequisites & Repository Discovery

Run all commands from the root of the target git repository:

1. Verify `gh` CLI works (`gh issue list --limit 1`). If unauthenticated or missing, inform the user and stop.
2. Detect the default branch (`gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`, falling back to `main`).
3. Read `AGENTS.md`, `CLAUDE.md`, or `README.md` (when present) to learn the repository's build, lint, test, and commit conventions.

---

## 1. Fetch Open Queue

```bash
gh issue list --state open --limit 50 --json number,title,labels,body,createdAt,updatedAt,url
```

---

## 2. Classification & Trigger Modes

Inspect each open issue's labels (case-insensitive) and optional issue-form metadata:

- **Paused / excluded from cron:** has any label `draft`, `rascunho`, `in-progress`, `em-andamento`, or `wip`, **OR** body contains `Draft (skip in cron)` / `Rascunho`.
- **Eligible for cron:** open issue that is **not** paused / in-progress.
- **Priority (bypasses batch minimum):** eligible issue with any label `urgent`, `urgente`, or `bug`, **OR** body contains `Urgent (trigger next cron)` / `Urgente`.

### CRON Mode (scheduled runs)
- Unless the prompt specifies another threshold (`N`), proceed **only if**:
  - `eligible >= 3` **OR** `priority >= 1`.
- If the threshold is **not** met: reply with a single concise line (e.g., `No triage needed: 2/3 eligible issues open, 0 urgent/bug.`) and **stop immediately** without asking questions or modifying anything.

### MANUAL Mode (on-demand chat invocation)
- Always proceed to Stage 1 showing **all** open issues (even if only 1 or 2 exist), clearly flagging `draft` / `in-progress` items.
- If there are 0 open issues, report that the queue is empty and stop.

---

## 3. Stage 1 — Summary & Multi-Select (Read-Only)

1. Present a concise table with: `#`, `Title`, `Labels / Priority`, `1-line Summary`, and `Ambiguities / Questions` (if any).
2. Ask the user to select which issues belong in this batch:
   - **If your environment provides an interactive multi-select tool** (such as `ask_question` with `is_multi_select: true`), call it listing each candidate issue (`#<N> — <short title> [<labels>]`) plus a `"None right now (keep in queue)"` option.
   - **Otherwise (e.g., Codex CLI / standard chat):** display the numbered list and ask the user to reply with the issue numbers to batch together (e.g., `#4, #7`) or `none`.
3. If the user selects none, stop cleanly with zero changes.

---

## 4. Stage 2 — Research, Quick Plan & Explicit Approval (Read-Only)

> [!CAUTION]
> **Hard rule:** NEVER edit files, create commits, push branches, or modify issue labels before receiving explicit approval at the end of Stage 2.

1. Read only the code files relevant to the selected issues (and run `gh issue view <N>` if an issue has comments or linked attachments). Check whether multiple selected issues touch overlapping files or share data models.
2. Present a short, actionable plan:
   - Per issue (`#N`): planned behavior change, affected files, tests/checks to add or run, and any open questions.
   - **Delivery strategy:** confirm whether to push a single consolidated commit to the default branch (standard when CI auto-publishes releases) or open a Pull Request (if the repo requires PRs or has branch protection).
3. Ask explicitly for confirmation before starting (`Approve and start batch` vs `Adjust selection / cancel`). If the user wants changes or cancels, adjust or stop with zero edits.

---

## 5. Stage 3 — Batch Execution, Validation, CI Watch & Release Closure

Only after explicit approval in Stage 2:

1. **Workspace hygiene:**
   - Run `git status --short`. If unrelated local modifications exist, warn the user and ask how to proceed before mixing them into the batch.
   - When the working tree is clean, update the base branch (`git pull --ff-only origin <default_branch>`).
2. **Claim issues (best-effort):**
   - Check whether `in-progress` (or `em-andamento`) exists (`gh label list`). Apply `gh issue edit <N> --add-label <label>` to each approved issue; if neither label exists and adding fails, continue gracefully.
3. **Implement & test:**
   - Implement every issue in the batch coherently following the repository's `AGENTS.md` conventions.
   - Add or update unit/integration/UI tests covering each change.
4. **Local validation:**
   - Run the repository's documented static checks, linters, builds, and/or test suites until everything passes cleanly.
5. **Single consolidated commit & push:**
   - Stage only the intended files and create **one commit** summarizing the batch with closing keywords in the body/footer:
     ```text
     Closes #12, Closes #15, Closes #18
     ```
   - Push to the agreed target (`git push origin <default_branch>`, or push a feature branch and run `gh pr create` if PR workflow was chosen).
6. **Monitor GitHub Actions & auto-fix failures:**
   - Check if workflows were triggered: `gh run list --limit 3`.
   - If a run is active/queued for this commit, watch it: `gh run watch <run_id> --exit-status`.
   - If the run fails: inspect `gh run view <run_id> --log-failed`, fix the root cause, re-run local validation, commit & push the fix, and watch the new run. Stop and ask the user if CI still fails after **2 fix attempts**.
7. **Close out & comment release version:**
   - Check the latest release (`gh release list --limit 1`).
   - Remove the in-progress label (`gh issue edit <N> --remove-label <label>`) if applied.
   - Comment on each issue in the batch with the commit SHA and published release tag (when applicable):
     ```bash
     gh issue comment <N> --body "Implemented in commit <short_sha> (CI passed; release <tag>)."
     ```
   - If the batch is aborted or blocked unrecoverably before completion, remove the in-progress label from all affected issues so they remain eligible in the queue.

For optional issue templates, labels, and CI cost-saving tips, see [references/templates-and-labels.md](./references/templates-and-labels.md).
