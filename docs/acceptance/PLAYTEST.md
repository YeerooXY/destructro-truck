# Destructro Truck — first playable

Open `Destructro Truck.exe`. No engine installation or internet is needed for the
exported Windows x86_64 build. The program starts at a menu.

This is an early physics prototype, not the completed MVP. It contains one fixed
test yard, a truck, two building types, momentum-granting structures, balloons,
Survival and 60-second Timed Efficiency, run scoring, pause, and restart. The yard
is tuned for short handling experiments. The final 5–8-minute Survival balance is
not implemented. Progress and money are not saved between attempts or sessions.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Launch when the meter reaches the center marker | Space | A / south button |
| Rotate in the air | A / D | Left stick |
| Directional nudge; hold to spend more energy | Arrow keys | Right stick |
| Restart | R | Y / north button |
| Pause | Escape | Start |
| Menu navigation | Arrow keys / Tab, Enter | D-pad / left stick, A |
| Back from controls/results, resume from pause | Escape | B / east button |

Any truck contact destroys a building and costs speed. The triangular wreck stays
collidable. Orange structures and blue balloon targets restore momentum. Balloons
also refill nudge energy. Keeping the body level helps preserve forward motion.
The HUD shows speed, distance, chain, score, and nudge energy. Runs end when the
truck stops being viable, or when the timed mode's clock expires.

## Feedback checkpoint

Try several launches, rotate through a landing, and use nudges to reach a balloon.
The useful feedback now is whether launch speed, bounce, rotation, nudge strength,
and the fixed momentum cost are readable and enjoyable. Note any collision that
feels unfair and whether you naturally want another attempt.

The accepted design requires mechanics to prove themselves with placeholders
before final art. The formal backlog milestone 7.6 has additional prerequisites
and is not claimed complete by this prototype.

## Verification boundaries

- Automated: contract validation, malformed input, score/money arithmetic,
  duplicate rewards, timer boundaries, uncapped Survival domain rules, distance,
  pause, restart, real engine collisions, speed/rotation bounds, and export contents.
- Scripted keyboard and gamepad button events pass through the input system.
  This does not replace physical controller testing.
- Actual Windows frames and an input-driven gameplay recording are captured.
  Visual review covers the menu, launch meter, HUD, and results at 1280×720.
- Human handling assessment, physical gamepad testing, broader hardware tests,
  final art/audio, progression/saves, the three product levels, and online services
  are still outstanding.

## Build from source

Run `tools/build/setup.ps1 -Templates`, then `tools/build/export.ps1` in PowerShell.
The export script runs the checks and produces `builds/Destructro-Truck-First-Playable.zip`.
The ZIP contains the executable, this guide, and engine/dependency license notices.
