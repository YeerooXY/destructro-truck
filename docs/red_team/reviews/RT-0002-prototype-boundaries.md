# RT-0002: Prototype pause, restart, and event boundaries

This is a bounded review of the current first-playable **prototype**, explicitly
assigned while implementation was underway. It is not canonical `7.6`/`8.3`
acceptance, a full implementation backlog crawl, or public-release approval.

- Reviewer: `Codex / Agent 8 Red Team (/root/red_team)`.
- Base commit: `02ce8ecc629f3bcc7390c9a66137d3880b275689`.
- The reviewed implementation was uncommitted. Exact original file hashes are
  in [`RT-0002-source-hashes.json`](RT-0002-source-hashes.json); the fixing
  implementation is identified by
  [`RT-0002-fixed-source-hashes.json`](RT-0002-fixed-source-hashes.json).
- The fixing manifest SHA-256 is
  `04C57B23948CCEC93F0EC2BE45F0EF1CD752AD5BFAE4B41C2D2E25F93DBAE6B5`.
- No PR existed for this review when performed. The ledger contains timestamps,
  exact finding state, and separate re-verification events.

## Reproduction and evidence

Environment: Windows, Godot `4.7.2.stable.official.ed1daf0bf`, headless execution
of the real `src/bootstrap/main.tscn` integration. The fixture injects accepted
commands and lifecycle callbacks. It does not claim physical controller testing,
normal-play reproduction of a stale callback, or simulated contacts as proof of
real building collision behavior.

Run from the repository root:

```powershell
& ./.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/red_team/test_prototype_boundaries.gd
```

The original fixture reported three assertion failures and two additional engine
errors. Full output is preserved in
[`RT-0002-initial-attacks.log`](RT-0002-initial-attacks.log). The fixture was then
extended with a paused-target callback and consecutive same-frame restarts while
retaining the original failing sequences.

The repaired implementation reported `RED_TEAM_PROTOTYPE failures=0`, exited 0,
and emitted no `SCRIPT ERROR` or `ERROR:` lines. See
[`RT-0002-reverification-1.log`](RT-0002-reverification-1.log). The tested fixture
SHA-256 is `FB9B29D294414AE2C069FD39D6750E7098652F556CC6060CDE9AFC49A8B9EAD3`.

After further physics and build-script updates, the same boundary fixture was
run again. It also passed with exit 0 and no engine errors. Its complete output is
[`RT-0002-reverification-2.log`](RT-0002-reverification-2.log), and its revision is
[`RT-0002-fixed-source-hashes-2.json`](RT-0002-fixed-source-hashes-2.json), whose
SHA-256 is `4524BC21120EE71C84EB3F353CE28216DD1D0174719693446E62FBA98D8C9F1E`.
The ledger retains the first passing events and adds `RV-0005` through `RV-0008`
for this later fixing revision.

## Findings and re-verification

### RT-0002-F1: Immediate pause discards a queued launch event

Severity: **high**. Owner: Agent 2, coordinating bootstrap integration.
Follow-up: `RT-0002-F1-FIX`. Re-verification: `RV-0001`, passed.

Start Survival, send launch, pause before the next physics callback, wait three
physics frames, then resume. Originally the truck was already launched but
the run session remained `ready`, with elapsed time 0 and no launch event.
This leaves the current attempt unable to run through the authoritative lifecycle.

`truck._physics_process()` flushed queued authoritative events before checking
whether simulation was disabled; bootstrap discarded the events while paused.
The owner changed publication to retain pending events while disabled and stop
draining the queue if a callback pauses publication.

The original sequence now produces state `running`, elapsed time approximately
0.0667 seconds, and exactly one accepted launch. This separately reproduced the
original failure scenario against the fixing manifest above.

### RT-0002-F2: Controller disconnect resumes an already paused game

Severity: **medium**. Owner: Agent 5, coordinating bootstrap integration.
Follow-up: `RT-0002-F2-FIX`. Re-verification: `RV-0002`, passed.

Launch, pause, then call the adapter callback that handles a disconnected
controller. Originally `_connection_changed` emitted the generic pause command,
and bootstrap toggled pause off. The run resumed with the pause menu removed.

The owner introduced a separate idempotent pause request wired to
`set_paused(true)`. Re-running the disconnect callback leaves `paused: true`,
session state `paused`, and the pause screen visible. This is callback-path
evidence; no physical device was disconnected during this test.

### RT-0002-F3: A previous run's event can reward the current run

Severity: **medium**. Owner: bootstrap integration, coordinating Agents 3 and 4.
Follow-up: `RT-0002-F3-FIX`. Re-verification: `RV-0003`, passed.

Construct a valid building event for one run, restart, launch the new run, and
deliver that old event to the coordinator. Originally the coordinator replaced
the producer's run ID with the current run ID while resequencing it. A synthetic
event from `yard_run_4` awarded 100 points and one destroyed building in
`yard_run_5`. No natural delayed callback was observed; the injection demonstrates
that the boundary discarded identity the downstream domain correctly validates.

The owner validates the source envelope and rejects its run ID before constructing
the integrated ordered event. The same old event now awards zero points and zero
destroyed buildings. Repeating a consumed world source also produces no extra
score in the deterministic domain; duplicate source reward was not a defect.

### RT-0002-F4: Repeated starts remove an already detached overlay

Severity: **low**. Owner: Agent 5.
Follow-up: `RT-0002-F4-FIX`. Re-verification: `RV-0004`, passed.

Start/restart repeatedly before the next frame frees a detached overlay. The
overlay reference remained valid after `remove_child`/`queue_free`; a following
`show_gameplay` attempted removal again. Godot reported
`p_child->data.parent != this` from `presentation.gd:134` twice during the initial
attack fixture. The fixture still ran; a visible gameplay failure or crash was
not established.

The owner clears the overlay reference during removal. Four same-frame restarts
now leave screen `gameplay` with no engine errors in the re-verification log.

## Other checks and limits

- A synthetic delayed body callback while the world is paused leaves the target
  unconsumed and destroyed count zero on the fixing implementation. This verifies
  the owner's preventive world guard; no original failing execution was recorded
  for that additional seam, so it is not counted as a confirmed finding.
- Existing integration proof was read: the test drives real contacts, eventual
  stop, distance observation, restart, and injected keyboard/gamepad launch.
  Its scripted steering and injected gamepad button are not a human gamepad
  walkthrough or evidence of enjoyable tuning.
- Initial source export inspection found a selected-main-scene export and explicit
  exclusion filters for tests, tools, docs, assembly, caches, build artifacts,
  and backend files. The build directory and acceptance artifacts did not yet
  exist at this inspection. Actual package contents, package hashes, clean-machine
  startup, and absence of developer tools must be checked against the built archive.
  Export configuration subsequently changed outside the pinned prototype review;
  Integration/Release is separately auditing the actual executable.
- At initial inspection, the build check and CI ran import plus unit suites.
  The later inspected build script also runs the full playable, live physics,
  and Red Team boundary fixtures. This review's results come from its explicit
  commands and recorded logs; hosted CI execution was not verified here.
- The export script packages everything in `builds/windows`. When packaging,
  verify the archive's exact file list so files left by previous exports cannot
  silently enter the deliverable. No contaminated archive was observed here.
- No online, save/progression persistence, full content, accessibility, physical
  controller, rendered-frame, or full-release acceptance is supplied by this review.

## Handoff

Original findings: 0 critical, 1 high, 2 medium, 1 low. All four have separate,
passing reproduction-based re-verification events against the identified fixing
implementation. No remaining failure was observed in the attacked prototype
paths. Later changes require checking whether these results still cover the
changed code; this report does not approve a merge or release.
