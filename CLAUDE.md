# RDR2 script mods (C++ / Script Hook RDR2)

Single-player Red Dead Redemption 2 mods. Each folder in `mods/` builds into one `.asi` file that
Script Hook RDR2 loads when the game starts.

## Layout

- `mods/<Name>/`: one mod. `*.cpp` files plus an optional `<Name>.ini` with default settings.
  New folders are picked up automatically by `CMakeLists.txt`.
- `shared/include/rdr2/`: code every mod uses.
  - `natives.h`: **generated** wrappers for all game natives (`PLAYER::PLAYER_PED_ID()` etc.).
  - `scripthook.h`: Script Hook exports (`scriptRegister`, `scriptWait`, `worldGetAllPeds`...).
  - `log.h`, `config.h`, `input.h`, `ui.h`, `joaat.h`: logging, .ini settings, key presses,
    on-screen text, compile-time hashes.
- `data/natives.json`: the native database (names, hashes, parameters, documentation).
- `tools/native.py`: native lookup. `tools/gen_natives.py`: regenerates `natives.h`.
- `scripts/*.ps1`: build, install into the game folder, read logs.
- `sdk/`: the Script Hook RDR2 SDK, downloaded by the user. Not committed.

## Commands

```
powershell -ExecutionPolicy Bypass -File scripts/build.ps1     # build all mods (Release)
powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1    # copy .asi/.ini into the game folder
powershell -ExecutionPolicy Bypass -File scripts/logs.ps1      # mod logs + ScriptHookRDR2.log
python tools/native.py <name|part of name|0xHASH> [-c] [-n NAMESPACE]   # look up a native
python tools/gen_natives.py [--update]                          # regenerate natives.h
```

## Rules for natives

- **Never guess a native's name, hash, parameters or behaviour.** Look it up first with
  `python tools/native.py` (add `-c` to search the documentation text) and read the comment.
  Many natives are undocumented or misnamed; say so when you rely on one.
- Call natives through the `natives.h` wrappers, never `invoke<>()` with a hand-typed hash.
- Check the comment for "does nothing since build ..." or "[Unused ...]" before using a native.
  Example: `HUD::_DISPLAY_TEXT` is dead; `ui::drawText` uses `UIDEBUG::_BG_DISPLAY_TEXT`.
- Literal text shown in game goes through `MISC::VAR_STRING(10, "LITERAL_STRING", text)`.
- For variadic natives (`VAR_STRING`), arguments are pushed as written: pass `float` (`1.0f`),
  never `double`.
- Model/weapon hashes: `rdr2::joaat("NAME")` at compile time or `MISC::GET_HASH_KEY("NAME")`.
- Never edit `natives.h` by hand. To refresh native data run `python tools/gen_natives.py --update`
  and commit both `data/natives.json` and `natives.h`. CI fails if they are out of sync.

## Rules for mod code

- Natives may only be called on the script thread: inside the function passed to
  `scriptRegister` and the functions it calls. Never call them from `DllMain` or the keyboard
  handler.
- The script loop must call `scriptWait(0)` every iteration. Never `Sleep()` or block on it.
  To wait, use `scriptWait(ms)` or compare `GetTickCount64()` across frames.
- Text drawn with `ui::drawText` lasts one frame, so draw it every frame.
- Re-apply per-player effects every frame or check `PLAYER::PLAYER_PED_ID()` each frame: the
  player's ped changes on death and in some missions.
- Log generously with `rdr2::log(...)`: startup, settings loaded, every user action, anything
  unexpected. The log is the only window into the running game.
- Put tunable values in the mod's `.ini` and read them through `rdr2::Config`, so the user
  can tweak them while the game runs instead of rebuilding.
- Single-player only. Don't use `NETWORK`, `ANTICHEAT` or other online natives, and don't build
  anything aimed at Red Dead Online.

## Workflow

You can't run the game or see the screen. The loop is:

1. Look up the natives you need, write the code, run `scripts/build.ps1`, fix any errors.
2. Run `scripts/deploy.ps1`. It refuses while RDR2 is running; if so, ask the user to close it.
3. Ask the user to start Story Mode and test, telling them exactly which keys to press and what
   they should see.
4. When they report back, run `scripts/logs.ps1` and read the logs before changing anything.

New mod: copy `mods/ExampleMod` to `mods/<NewName>`, rename `ExampleMod.ini` to `<NewName>.ini`,
and replace the code. Use keys other mods don't (ExampleMod uses F9 and F10).

## Troubleshooting

- `ScriptHookRDR2.lib not found`: the user hasn't extracted the SDK into `sdk/` (see README).
- Unresolved external `__imp_?...@@...` for a Script Hook function: the declaration in
  `scripthook.h` doesn't match the SDK. Run `dumpbin /exports sdk\lib\ScriptHookRDR2.lib`
  and fix `scripthook.h` and `ci/ScriptHookRDR2.def` together.
- The mod doesn't load at all: check `ScriptHookRDR2.log` in the game folder. After a game
  update Script Hook stops working until a new Script Hook version is released.
- `deploy.ps1` can't find the game: write the game folder path into `game-dir.txt` at the
  repo root (it's gitignored).
