# RDR2 mods

C++ script mods for Red Dead Redemption 2 (story mode), built with Script Hook RDR2 and set up
for working with [Claude Code](https://claude.com/claude-code).

It includes an example mod: **F9** toggles god mode and **F10** refills your health, stamina and
Dead Eye cores.

## One-time setup (on the PC where RDR2 is installed)

Install [Claude Code](https://claude.com/claude-code) for Windows, create a folder such as
`C:\dev`, open Claude Code in it, and ask:

> Install Git with winget, clone https://github.com/PatBad/RDR-2-modding, and run
> scripts/setup.ps1 from the clone.

Keep the repo out of folders synced by OneDrive (which includes Documents on many PCs),
Dropbox or Google Drive, out of the RDR2 game folder, and out of Program Files. Building
creates thousands of small files, which sync clients slow down or lock mid-build.

Or do it yourself: install [Git](https://git-scm.com/download/win), clone this repo, and run
this from the repo folder with the game closed:

```
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

`setup.ps1` checks each item and only installs what's missing, so it's safe to run again:

1. Installs Git, Python 3 and Visual Studio Build Tools with the C++ workload, using `winget`.
   Click **Yes** on the Windows prompts. Build Tools is a download of several GB.
2. Finds the RDR2 folder. If it's somewhere unusual, add `-GameDir "D:\Games\Red Dead Redemption 2"`.
3. Installs Script Hook RDR2 (`ScriptHookRDR2.dll`, `dinput8.dll`) into the game folder and
   its SDK into `sdk/`. It downloads them from http://www.dev-c.com/rdr2/scripthookrdr2/. If
   that site blocks the download, download both zips from it into your Downloads folder and
   run the script again.
4. Builds the example mod and installs it into the game.

It ends with a summary of what's OK and what still needs doing. To check without changing
anything, add `-CheckOnly`. If Windows says access is denied to the game folder, run PowerShell
as administrator.

Then start Story Mode. A message in the top-left corner says the mod loaded; press F9 and F10.
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
