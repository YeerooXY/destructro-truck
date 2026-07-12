# Destructro Truck Task Dependency Audit

## Result

- Total tasks: **114**
- Agents: **8**
- Missing task references: **0**
- Circular dependencies: **0**
- Dependency graph: **acyclic**
- Topological dependency levels: **27** (`wave-00` through `wave-26`)
- Final terminal task: **7.15 — Accept the complete MVP release candidate**

The machine-readable sources of truth are:

- `assembly/generated/task_backlog.json`
- `assembly/generated/task_batch_index.json`

The detailed human-readable task definitions are the eight agent files in this directory.

## Exact resolution of previously provisional dependencies

Several human-readable drafts used phrases such as “plus the later project-skeleton task” or “plus a later Agent 7 gate.” The canonical backlog resolves these as follows:

- `2.1`, `3.1`, `4.1`, and `5.1` depend on `6.1`.
- `1.9` waits for stable run semantics from `4.5`, `4.7`, `4.8`, and `4.10` before the compact run-record contract is finalized.
- `3.14` depends on the accepted grey-box vertical slice `7.6`.
- `4.16` depends on `7.6`.
- `5.15` depends on `7.6` only; it does **not** depend on `7.9`, because `7.9` consumes `5.15`.
- `6.15` depends on the integrated performance/accessibility gate `7.13`.
- `6.16` depends on `7.10`, `7.12`, `7.13`, and `7.14`, which are all upstream of the final release acceptance.
- `7.15` depends on the final Red Team review `8.12`.

This resolution removes the most likely hidden cycle:

`5.15 → 7.9 → 5.15`

The canonical form is instead:

`7.6 → 5.15 → 7.9`

## Execution semantics

Agent prefixes identify ownership, not global order. A task may begin only when every task listed in its `depends_on` array is accepted.

The dependency levels in `task_batch_index.json` are a topological grouping, not a command to activate every task in a level simultaneously. Normal useful concurrency remains **2–5 agents**. Use **4–6** only when tasks are genuinely ready and file ownership is disjoint.

Integration and Red Team tasks are interleaved by risk and boundary readiness rather than postponed to the end.

## Boss-task chain

The major milestone chain is:

`7.6 grey-box acceptance → 3.14 fixed levels + 4.16 offline game brain + 5.15 player-facing flow → 7.9 complete offline integration → 6.15 public package → 7.14 clean-machine build → 6.16 online/release proof → 8.12 final adversarial review → 7.15 final MVP acceptance`

## Audit method

The complete directed graph was assembled from all explicit task dependencies, validated for missing references, and processed using topological sorting. All 114 nodes were emitted successfully, leaving no cycle nodes.
