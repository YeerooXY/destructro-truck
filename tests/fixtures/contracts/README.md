# Contract fixtures

Valid fixtures must validate after JSON parse and a JSON round trip. Invalid fixtures fail without throwing and expose a machine-readable path/code. The suite also changes one property at a time to cover bad types, unsupported versions, malformed vectors, event ordering, result arithmetic, and read-only state ownership.

| Fixture | Meaning |
| --- | --- |
| `ruleset.valid.json` | Exact known debug ruleset and governing versions. |
| `ruleset.invalid.json` | Rejects unregistered level version at `$.level_version`. |
| `debug_level.valid.json` | Fixed positions, two building types, shared propane variant, single convex wrecks, deterministic aerial schedule. |
| `run_result.valid.json` | Offline Survival result with explicit breakdown and debug ineligibility. |
| `hud_state.valid.json` | Launch-ready HUD using only run/truck observations and display data. |
| `command_nudge.valid.json` | Analog direction and strength, independent of keyboard/gamepad/touch mapping. |
| `command_nudge.invalid.json` | Rejects diagonal direction whose length exceeds one. |
| `events.valid.json` | Canonical run-scoped ordering and authored world reward inputs. |

Debug fixtures are original sample data. They are not tuned release content or proof of gameplay acceptance.
