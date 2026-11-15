# AdjustableMirrors
The mod that allows you to adjust your mirrors, to make your cab-view driving experience that more pleasureable.

Available on modhub:
- [FS19](https://www.farming-simulator.com/mod.php?mod_id=135313)
- [FS22](https://www.farming-simulator.com/mod.php?mod_id=287548)
- [FS25](https://www.farming-simulator.com/mod.php?mod_id=327359)

## Linux: fixing the Farming Simulator IDE extension

The official [Farming Simulator IDE Support](https://marketplace.visualstudio.com/items?itemName=GIANTSSoftware.farmingsimulator-ide)
VS Code extension is built around Windows conventions. On Linux two things
don't work out of the box:

1. **LuaLS language server** — the extension only bundles a Windows (PE) build
   (`server/lua-language-server/bin/lua-language-server.exe`), so the "FS Lua"
   output channel shows a spawn error and IntelliSense never starts.
2. **Game profile lookup** — the game log watcher looks for the FS profile in
   `~/Documents/My Games/FarmingSimulator<year>` (a Windows path). With
   Steam/Proton the profile lives inside the Proton prefix instead.

`scripts/fix-luals-linux.sh` handles both:

- Downloads the matching official **Linux x64** LuaLS build from the upstream
  [LuaLS releases](https://github.com/LuaLS/lua-language-server/releases) and
  symlinks it over the bundled `.exe` (Node's `spawn()` doesn't care about the
  file name on Linux). The version is read from the extension's bundled
  `changelog.md`, so the script tracks extension updates automatically.
- Creates `~/Documents/My Games/FarmingSimulator<year>/` as a real directory
  with symlinks to the Proton prefix profile's `game.xml` and `log.txt`, so
  the game log viewer can find them. (A plain symlink to the profile
  directory doesn't work: the extension filters with `isDirectory()`, which
  is false for symlinks.)
- Symlinks `modfiles/` into the game's `mods/` folder as
  `FS25_AdjustableMirrors`. An unpacked mod folder takes precedence over a
  same-named `.zip` in-game, so edits to `modfiles/` are picked up directly
  without re-deploying.

- Run it via the VS Code task **`FS Lua: Fix Linux LuaLS`**
  (`Terminal > Run Task...`), or directly: `bash scripts/fix-luals-linux.sh`
- The script is idempotent — re-running it after an extension update only
  re-downloads if the bundled LuaLS version changed.
- Downloaded binaries are cached in `.luals/` (gitignored).
- After the script succeeds, run **`FS Lua: Restart Language Server`** from the
  command palette (or reload the window).

### Removing the mod link before playing

The `FS25_AdjustableMirrors` symlink shadows the deployed `.zip` in-game.
If you need to join a server that requires the mod, remove the link first:

- VS Code task **`FS Lua: Remove Mod Link (for playing)`**, or
  `bash scripts/fix-luals-linux.sh --remove-mod-link`

Re-run **`FS Lua: Fix Linux LuaLS`** to restore the dev link afterwards.

### Engine IntelliSense (fsLua.gamePath)

For full engine API IntelliSense the extension needs to find the game
installation (it reads `sdk/debugger/scriptBinding.xml` for function
signatures). Set `fsLua.gamePath` in `.vscode/settings.json` to the folder
containing the game executable and `data/` directory:

```json
"fsLua.gamePath": "/path/to/Farming Simulator 25"
```

Pure-Lua engine classes that live in the packed `dataS.gar` (e.g.
`SpecializationUtil`) are not covered by the XML bindings; they are listed in
`Lua.diagnostics.globals` in `.vscode/settings.json` to suppress
undefined-global warnings.
