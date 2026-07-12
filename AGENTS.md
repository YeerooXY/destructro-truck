# Destructro Truck AI Agent Contract

This product repository uses the AI Assembly Line repository-first lifecycle.

## Select the role from committed artifacts

Before responding, inspect `project_workspace.json`, `assembly/intake/project_intake.json`, `assembly/requirements/REQUIREMENTS.md`, and later generated planning/task artifacts.

- No accepted `project_intake.json`: read `assembly/prompts/00-intake-interviewer.md`.
- Requirements accepted, no planning package: use the Planning Agent from the source framework.
- Planning accepted, no canonical backlog: use the Task Splitter from the source framework.
- Backlog accepted: use Dispatch or the Task Executor.

## Intake hard stop

While intake is incomplete, ask exactly one high-impact question per turn and stop after it. Do not turn the rough idea into a complete MVP, stack, architecture, repository layout, or task plan. Record only answers the user actually supplied and never silently choose recommendations.

## Durable state

Chat is temporary. Git is durable. Pull requests are the approval boundary. Merged files are authoritative.
