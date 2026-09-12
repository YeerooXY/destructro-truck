# Red Team review workflow

Task `8.1` initializes this workflow. The source of truth is
[`red_team_review_index.json`](../../assembly/generated/red_team_review_index.json).
Review reports live in [`reviews/`](reviews/); copy
[`TEMPLATE.md`](reviews/TEMPLATE.md) for a new review.

Setup does not accept an implementation, merge, milestone, or release. A planning
review is explicitly identified as `planning` and does not satisfy `8.2` or `8.3`.

## Create and complete a review

1. Allocate the next unused `RT-NNNN` ID from the index. Finding IDs append `-F1`,
   `-F2`, and so on. IDs are permanent; coordinate allocation in concurrent work.
2. Add an index entry immediately with `outcome: in_progress`, `completed_at: null`,
   and `reverification_status: not_required`. Name the reviewer, review kind,
   task IDs, exact full commit SHA, PR URL if present, files/contracts, selection
   reason, and UTC start time. An absent PR must have an explicit explanation.
3. Pin the reviewed revision. Record any working-tree changes and their diff or
   artifact hashes; a base commit alone does not identify uncommitted work.
   For packages, record the actual package hash and the tested environment.
4. Test the assigned scope against its accepted requirements and original
   acceptance evidence. Record commands, fixtures/input, environment, expected
   and actual behavior, output/artifact references, and limits. Distinguish
   reproduced defects, evidence gaps, and untested hypotheses.
5. Record every finding with severity, classification, reproduction, expected
   behavior, owning lane, a specific follow-up reference and fix scope, and
   `status: open`. Red Team assigns the work; the owning lane implements it.
   A follow-up such as `RT-0001-F1-FIX` is a review-local work reference until
   Dispatch links an accepted backlog task or PR. It is not a new canonical task.
6. Finish with a UTC completion time, one outcome below, severity counts,
   critical finding IDs, explicit release recommendation, and untested limits.
   Record zero-finding reviews too. Run the validator before handing off.

All original review outcomes, evidence, and finding identities remain durable.
Append new evidence and re-verification events instead of erasing history.

## Severity and outcome

| Severity | Meaning within accepted scope |
| --- | --- |
| critical | A release-blocking compromise of game integrity, private data, recoverable progress, or ability to play; any unresolved critical finding blocks `7.15`. |
| high | A major required behavior, trust boundary, or milestone execution path is broken; fix ownership and re-verification are mandatory. |
| medium | A bounded defect or evidence gap can cause incorrect behavior or miss an important integration failure. |
| low | A minor clarity, traceability, or non-blocking defect. |

Severity describes impact supported by evidence; an untested attack idea is a
review target, not a confirmed critical defect. Do not invent extra release gates.

| Review outcome | Meaning |
| --- | --- |
| in_progress | Selected review is underway; no completion claimed. |
| no_findings | Assigned scope was reviewed with no findings; evidence and limits are still required. |
| findings | Review is complete and recorded findings; this is not merge approval. |
| blocked | Review cannot be completed with the available revision, environment, or evidence; record exactly what is missing. |

Finding states are `open`, `fix_claimed`, `resolved`, and `reopened`. The owner's
claim of a fix changes only to `fix_claimed`, with an exact fixing revision and
evidence reference. Red Team cannot silently implement or waive its own finding.
An owner decision to accept residual risk is recorded as an external decision;
it does not turn an unresolved finding into a verified fix or waive a critical gate.

Review re-verification status is `not_required` when it has no findings, `pending`
while findings await a fix/retest, `partial` when some are verified resolved, and
`complete` only when every finding has a passing re-verification event.

## Re-verify a fix

1. The owning lane links the fix task/PR, exact fixing commit (or a hashed working
   diff), changed files, and claimed fix evidence to the finding. Keep the original
   reproduction and original reviewed revision intact.
2. A reviewer re-runs the original reproduction against that fixing revision and
   checks the affected boundary for regressions. Merely reading a claimed fix or
   observing unrelated green tests is insufficient.
3. Append a distinct top-level `reverification_events` entry, named `RV-NNNN`,
   containing `finding_id`, `reviewer_identity`, `fix_reference`,
   `fix_commit_or_artifact`, `performed_at`, `original_reproduction`,
   `evidence`, and `result` (`pass`, `fail`, or `inconclusive`).
4. Only a passing event with reproduction evidence permits `status: resolved`.
   Set the finding's `reverification_event_id` to that event. A failed retest
   reopens the finding; an inconclusive retest leaves it unclosed. A later failed
   event cannot be hidden behind an earlier passing event.
5. Recompute review re-verification status, retain severity and follow-up history,
   validate the index, and hand the result to Integration/Verification. Agent 8
   supplies evidence and a recommendation, never merge or release approval.

## Backlog crawl

Read `assembly/generated/task_backlog.json`, its task detail files, accepted task
proof under `assembly/generated/task_runs/`, merged PRs, and this ledger. The
backlog currently lists dependencies but no per-task completion timestamps;
absence of a status is not completion. Require explicit acceptance evidence for
the selected task and every dependency. Missing proof means the task is not yet
eligible for the completed-task crawl.

Prioritize eligible unreviewed work with high risk or many dependents: shared
contracts, real contacts/events, score/progression/save, competitive submissions,
privacy, and packages. Within that selection, process topologically, then by
acceptance time, then numerically by task ID for ties. Avoid reviewing a consumer
before an eligible selected prerequisite. Skip trivial tasks only with a recorded
reason in the crawl report. Changed commits or important uncovered surfaces can
justify another review; a review of an older revision does not cover a new one.

Re-verify claimed critical/high fixes before adding low-risk crawl work. Record
each crawl's candidate set, acceptance sources, selection/skip reasons, ordering,
and any missing evidence even if it selects nothing. An explicitly assigned
planning inspection may run earlier, but label it `planning` and keep it separate
from completed implementation coverage. Tasks `8.2` through `8.12` retain their
canonical dependencies and acceptance criteria.

## Validate

From the repository root, in Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/red_team/validate_ledger.ps1
```

The validator checks required traceability fields, unique review/finding/event
IDs, report links, outcomes/counts, finding ownership, and closure linked to the
latest passing re-verification event. It validates ledger consistency; it cannot
prove that evidence is truthful or authorize a release. Evidence still needs review.
