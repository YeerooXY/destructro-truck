# Local Setup

Use the current implementation branch or an accepted implementation on `main`.

```powershell
./tools/build/setup.ps1 -Templates
./tools/build/check.ps1
./.tools/godot/Godot_v4.7.2-stable_win64.exe --path .
./tools/build/export.ps1
```

The engine is portable and lives in ignored `.tools/`. Export setup installs
Windows x86_64 templates in Godot's user data directory. The initial template
download contains all platforms. To use an existing installation, set `GODOT_BIN`
to its Godot 4.7.2 console binary. Python and Node are not required.
