# Destructro Truck Design Principles

These principles guide every human and AI contributor. If an implementation conflicts with them, the implementation should change unless the project owner explicitly approves a design change.

## 1. Gameplay First

If a choice improves the arcade experience but slightly complicates implementation, gameplay wins. Destructro Truck is not a physics simulator.

## 2. The MVP Is Sacred

Nothing enters the MVP merely because it appears small. Additions must replace accepted scope, receive an explicit requirements change, or move to post-MVP.

## 3. Prototype Before Polish

Every mechanic must prove that it is fun with placeholder assets, debug hitboxes, and minimal UI before final art or presentation work begins.

## 4. Data Before Bespoke Code

Content variants should preferably be expressed through reusable data and shared behavior rather than one-off scripts. New buildings, aerial targets, boosts, and rewards should reuse established contracts whenever possible.

## 5. Player Skill Over Player Stats

Progression should expand planning, routing, information, timing, and tactical options rather than merely increasing numbers. The radar system is the model: early upgrades give crude warnings, while later upgrades become a richer planning aid.

## 6. Every Object Has a Purpose

Every gameplay object must clearly answer:

- What resource does it cost?
- What resource does it provide?
- Why would the player choose to interact with it?

Objects without a meaningful gameplay role do not belong in the MVP.

## 7. Predictable, Not Realistic

Interactions should be consistent enough for players to learn and master. Arcade readability and repeatable outcomes matter more than physical realism.

## 8. Readability Beats Detail

Clear silhouettes, obvious feedback, one ground-level building layer, distinct aerial opportunities, and understandable impacts take priority over visual complexity.

## 9. Reuse Before Inventing

Before introducing a new mechanic, ask whether an existing object or system with different data can create the same gameplay result.

## 10. Evidence Beats Opinion

When contributors disagree, compare prototypes, tests, complexity, performance, MVP impact, and maintainability. The integration agent summarizes the evidence; the project owner resolves remaining ties.

## 11. Fun Wins

When technically viable options are otherwise equivalent, choose the one that produces the better play experience—even when it uses deliberately exaggerated arcade behavior.

## 12. Every Second Should Contain a Decision

The player should continually make small choices about routes, altitude, buildings, boosts, nudges, recovery objects, and upcoming opportunities. Passive waiting is a signal that the design needs improvement.

## Collaboration Guardrail

Humans and AI agents may make local decisions within accepted subsystem boundaries and contracts. They may not silently expand the accepted MVP. Out-of-scope ideas belong in post-MVP notes or require an explicit requirements change.
