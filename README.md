# RDR2 mods

C++ script mods for Red Dead Redemption 2 (story mode), built with Script Hook RDR2 and set up
for working with [Claude Code](https://claude.com/claude-code).

It includes an example mod: **F9** toggles god mode and **F10** refills your health, stamina and
Dead Eye cores.

## One-time setup (on the PC where RDR2 is installed)

1. **Install the tools**
   - [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) (2022 or later)
     with the **Desktop development with C++** workload. That includes the compiler and CMake.
   - [Git](https://git-scm.com/download/win) and [Python 3](https://www.python.org/downloads/)
     (Python is only for the native lookup tools).
   - [Claude Code](https://claude.com/claude-code) for Windows.

2. **Install Script Hook RDR2 into the game.** Download it from
   http://www.dev-c.com/rdr2/scripthookrdr2/ and copy `ScriptHookRDR2.dll` and `dinput8.dll`
   into the game folder (the folder with `RDR2.exe`). You don't need `NativeTrainer.asi`.

3. **Add the SDK to this repo.** From the same page, download the SDK and extract it into the
   `sdk/` folder here, so that `sdk/lib/ScriptHookRDR2.lib` exists. (It isn't committed to git.)

4. **Tell the scripts where the game is**, if it isn't in the default Steam, Rockstar or Epic
   location: put the folder path in a file called `game-dir.txt` at the repo root.

5. **Build and install the example mod** (game closed):
   ```
   powershell -ExecutionPolicy Bypass -File scripts/build.ps1
   powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1
   ```
   Start Story Mode. A message in the top-left corner says the mod loaded. Press F9 and F10.
   If nothing appears, run `scripts/logs.ps1` (or ask Claude to).

## Working with Claude Code

Open this folder in Claude Code and describe what you want, for example *"make a mod that
slows time while I hold Alt"*. `CLAUDE.md` tells Claude how this project works: it looks up
every native in the database before using it, builds, installs the mod, then asks you to test
and reads the logs when you report back.

Things that make it go well:
- **Close the game before Claude installs a new build.** The game locks loaded mods and only
  loads them at startup.
- **Say exactly what happened** when you test ("nothing on screen", "the game crashed when I
  pressed F9"). Claude can't see your screen.
- **Tweak numbers in the mod's .ini file** in the game folder while playing; the mod picks up
  changes without a restart.
- **Commit each version that works**, so you can go back when a change breaks something.

## Layout

| Path | What it is |
|---|---|
| `mods/<Name>/` | One mod each; builds to `<Name>.asi` |
| `shared/include/rdr2/` | Shared code: native wrappers, logging, settings, input, on-screen text |
| `data/natives.json` | Native database from [alloc8or/rdr3-nativedb-data](https://github.com/alloc8or/rdr3-nativedb-data) |
| `tools/native.py` | Look up natives: `python tools/native.py invincible -c` |
| `tools/gen_natives.py` | Regenerate `natives.h`; `--update` fetches the latest database |
| `scripts/` | `build.ps1`, `deploy.ps1`, `logs.ps1` |

GitHub Actions builds every push on Windows to catch compile errors. It links against a
stand-in for the Script Hook library, so its `.asi` files are a build check, not a substitute
for testing in the game.

## Safety

- **Story mode only.** Script Hook RDR2 disables itself in Red Dead Online, and modding online
  can get your account banned.
- **Game updates break Script Hook** until a new version comes out. Consider holding off on
  updates, or wait for the Script Hook release before playing.
- **Only install `.asi` and `.dll` files from sources you trust.** They run with full access to
  your PC.
- To remove all mods, delete the `.asi` files (and `ScriptHookRDR2.dll`, `dinput8.dll`) from the
  game folder, or use your launcher's "verify files" option.
