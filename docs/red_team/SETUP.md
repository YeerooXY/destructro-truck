# Task 8.1 setup evidence

Prepared on 2026-09-12 by `Codex / Agent 8 Red Team (/root/red_team)`.
This records workflow setup and its validation; it does not accept implemented
features, task `7.6`, Red Team tasks `8.2`/`8.3`, or a public release.

## Deliverables

- `README.md`: IDs, scope pinning, evidence, severity/outcome definitions,
  owning-lane follow-ups, completed-task crawl selection, and re-verification.
- `reviews/TEMPLATE.md`: the reusable review report template.
- `validate_ledger.ps1`: read-only ledger consistency validation.
- `assembly/generated/red_team_review_index.json`: initialized version `0.2.0`,
  retaining the original required fields and adding explicit findings and
  separate re-verification events.
- `reviews/RT-0001-first-playable-plan.md`: the actual assigned read-only planning
  review. Two open planning/evidence findings; zero implementation reviews and
  zero claimed fixes or re-verification events.

## Validation performed

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/red_team/validate_ledger.ps1
```

Observed: `Red Team ledger valid: 1 reviews, 2 findings, 0 re-verification events.`

Four synthetic checks used temporary copies of the index, then removed those
copies. They did not alter real finding state or add imaginary product reviews:

| Validator case | Observed result |
| --- | --- |
| Completed review with zero findings and matching counts/state | Accepted |
| Finding set to resolved with a fix claim but no separate re-verification event | Rejected |
| Same synthetic finding with matching passing reproduction event | Accepted |
| Older passing closure retained after a newer failed re-verification | Rejected |

`git diff --check -- assembly/generated/red_team_review_index.json docs/red_team`
reported no whitespace errors. No implementation, requirements, canonical backlog,
or other lane files were changed by this task. No commit or push was performed.

The validator enforces consistency of the claimed metadata, including closure
references. It cannot establish that an experiment really happened; reviewers
must inspect the cited evidence before accepting that claim.
