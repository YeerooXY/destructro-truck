# Destructro Truck

A physics-driven truck destruction game built in Godot 4.7.2 and GDScript.

The first playable prototype has a fixed test yard, launch timing, momentum costs,
building destruction and wrecks, aerial recovery, rotation/nudge controls, scoring,
two run modes, pause, and rapid restart. It is ready for handling feedback before
progression and final presentation. It is not the complete MVP.

Read [the playtest guide](docs/acceptance/PLAYTEST.md) for controls and limitations.
The [checkpoint evidence](docs/acceptance/FIRST_PLAYABLE.md) includes actual
gameplay footage, screenshots, and build checks.

```powershell
./tools/build/setup.ps1 -Templates
./tools/build/check.ps1
./.tools/godot/Godot_v4.7.2-stable_win64.exe --path .
./tools/build/export.ps1
```

The portable Windows package is written to `builds/Destructro-Truck-First-Playable.zip`.
Engine downloads, captures, and builds are ignored by Git.

This repository uses the AI Assembly Line repository-first workflow. Accepted requirements, planning, tasks, implementation, and proof belong in this repository and move through reviewable pull requests.
