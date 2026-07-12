# Destructro Truck Planning Role Review

This file records project-owner approvals made during the planning consultation. Draft generated prompts remain provisional until all roles are reviewed and the planning PR is opened.

## Approved roles

### Contract Steward

**Approved scope:** Option B — contracts plus deterministic shared domain types.

The Contract Steward owns shared schemas, versioned events, DTOs, serialization formats, value objects, and small deterministic calculations genuinely shared by multiple lanes. It does not own lane-specific gameplay, scoring formulas, world behavior, UI behavior, or backend service implementation. It must define shared interfaces before dependent implementation and must not silently change accepted product rules.

## Pending roles

- Core Gameplay and Physics Builder
- World Objects and Level Runtime Builder
- Run Rules, Scoring, and Progression Builder
- UI, Input, and Presentation Builder
- Online Services and Release Infrastructure Builder
- Integration and Verification Agent
- Red Team Verifier
