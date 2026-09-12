# RT-0001: First playable dependency inspection

This is a completed **planning review** of accepted task artifacts. It does not
review any implemented game, approve `7.6`, or complete `8.2`/`8.3`.
Reviewer: `Codex / Agent 8 Red Team (/root/red_team)`.
Exact timestamps and finding states are in the durable index.

Reviewed base commit: `02ce8ecc629f3bcc7390c9a66137d3880b275689`.
No PR for this local inspection. Relevant backlog and Agent 1/4/5/7 task files
had no working-tree diff from that commit when inspected. Other agents were
working on foundation files; those implementations were outside this review.

## Evidence and limits

Read `AGENTS.md`, the intake/requirements, design principles, generated project
specification, repository plan, agent prompts, canonical backlog, dependency audit,
and relevant task details. The canonical backlog is authoritative where prose
still contains provisional dependency wording, as the dependency audit states.

Using Windows PowerShell, build a map keyed by `task_id`, then traverse each
`depends_on` entry recursively starting at `7.6`, adding each ID only once.
The resulting transitive prerequisite set contains **57 tasks**, spanning
dependency levels 0 through 15; `7.6` is at level 16. This is a dependency inspection,
not an estimate of elapsed development time or proof those tasks are accepted.

Reproduce the specific dependency findings:

```powershell
$backlog = Get-Content assembly/generated/task_backlog.json -Raw | ConvertFrom-Json
$byId = @{}
foreach ($task in $backlog.tasks) { $byId[$task.task_id] = $task }
$ancestors = @{}
function Visit-Dependency([string]$taskId) {
    foreach ($dependency in $byId[$taskId].depends_on) {
        if (-not $ancestors.ContainsKey($dependency)) {
            $ancestors[$dependency] = $true
            Visit-Dependency $dependency
        }
    }
}
Visit-Dependency '7.6'
$ancestors.Count
'1.9','4.13','7.1','6.2','8.2','5.4' | ForEach-Object {
    '{0}: {1}' -f $_, $ancestors.ContainsKey($_)
}
```

Observed output: `57`, then `1.9: True`, `4.13: True`, `7.1: False`,
`6.2: False`, `8.2: False`, and `5.4: False`.

No runtime, physics, input-device, build, or completed-task evidence was tested.
No completed implementation tasks were selected for the backlog crawl; this was
the independently assigned inspection accompanying workflow setup.

## RT-0001-F1: Later compact-record work blocks the first playable

Severity: **high**. Classification: planning. State: open.

Agent 1's task file, Wave guidance, explicitly says `1.9–1.13` must not block the
first playable. The planning handoff also orders the playable truck/contact loop
before the complete local save/progression loop and stable compact records.

The canonical prerequisite chain is:

`7.6 requires 5.10; 5.10 requires 4.14; 4.14 requires 1.9 and 4.13`.

This makes the compact-record contract and assembly, atomic persistence, and much
of progression prerequisites of the first playable acceptance. Independently,
`5.7` requires equipment work `4.10`, and `7.5` requires radar `4.11`/`5.9`.
Following the graph without qualification postpones the prototype; omitting those
tasks while claiming accepted `7.6` would violate the task handoff's dependency rule.

Owner: Dispatch / active lifecycle owner, coordinating Agents 1, 4, 5, and 7.
Follow-up: **RT-0001-F1-FIX**. Reconcile the conflicting milestone guidance and
canonical dependencies through an explicit reviewed lifecycle change, or retain
the canonical dependencies and label an earlier prototype accurately as partial.
This review changes neither requirements nor the backlog and does not choose
that policy on the owner's behalf. Foundation work remains dependency-ready.

Re-verification must traverse the accepted graph again and compare its actual
first-playable prerequisites with the accepted milestone wording and proof claims.

## RT-0001-F2: Foundation and contract review are not enforced by the playable path

Severity: **medium**. Classification: evidence gap. State: open.

The task handoff lists `7.1` foundation smoke integration before the `7.6` milestone;
`8.2` calls for critical contract ambiguities to be recorded before dependent
high-risk work. However, `7.1`, CI task `6.2`, and `8.2` are not ancestors of `7.6`.
The graph can therefore schedule all playable prerequisites without selecting
these checks. This establishes a scheduling/evidence gap, not a failed build or
an assertion that the checks have been skipped in the current implementation.

Owner: Dispatch / Agent 7, coordinating Agent 8.
Follow-up: **RT-0001-F2-FIX**. Make those existing checks explicit in execution
handoff and retain their accepted evidence before claiming the corresponding
foundation/contract coverage. If enforcement requires graph changes, route those
through the lifecycle owner. No new product requirement is proposed.

Re-verification must inspect actual accepted task proof and the execution handoff;
an altered graph alone is not evidence that a check ran.

## Untested seams for the real grey-box review

These are test targets from the existing acceptance criteria, not confirmed findings:

- A building can deliver multiple truck/wheel/corner contacts in one physics
  step. Destruction, fixed speed loss, optional impulse, score, and money must each
  happen once. Recontact with the wreck must not destroy/reward the building again.
- A rigid-body impact plus the configured speed cost can accidentally charge
  the same loss twice. Specify the velocity observation/apply phase, and test
  zero speed, diagonal impact, and cost larger than available speed.
- Persistent ground/wreck contacts must not repeatedly inject bounce energy.
  Holding rotation at a translational stop must not evade eventual-stop detection
  indefinitely; capped angular velocity by itself does not prove that property.
- Held nudge, conflicting axes, duplicate launch edges, pause, disconnect, and
  restart must preserve command timing and bounded resource spending. Real device
  walkthroughs and injected command tests are different evidence.
- Deferred collider replacement and old events/snapshots can survive rapid
  restart. Run identity, object identity, event order, input, UI overlays, and
  completion state must reset together without importing another lane's nodes.
- `7.6` begins with menu/start, while `5.4` is outside its ancestors. Assign the
  minimal start path explicitly; a development harness must not be presented as
  evidence for the complete menu/navigation task.
- `3.7` balloons must recover actual momentum through the accepted resource
  interface. An event that only increments score or changes VFX does not prove
  the intended momentum economy.

## Handoff

Two planning/evidence findings: 0 critical, 1 high, 1 medium, 0 low.
Both remain open and need owning-lane follow-up. No fixing change or
re-verification has been claimed. This review provides no release recommendation
about an implemented product; release readiness was outside its scope.
