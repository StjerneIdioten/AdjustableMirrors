# AdjustableMirrors
The mod that allows you to adjust your mirrors, to make your cab-view driving experience that more pleasureable.

Available on modhub:
- [FS19](https://www.farming-simulator.com/mod.php?mod_id=135313)
- [FS22](https://www.farming-simulator.com/mod.php?mod_id=287548)
- [FS25](https://www.farming-simulator.com/mod.php?mod_id=327359)

## Linux: fixing the Farming Simulator IDE extension's Lua language server

The official [Farming Simulator IDE Support](https://marketplace.visualstudio.com/items?itemName=GIANTSSoftware.farmingsimulator-ide)
VS Code extension only bundles a **Windows** build of the LuaLS language server1fs
(`server/lua-language-server/bin/lua-language-server.exe`), so on Linux the
"FS Lua" output channel shows a spawn error and IntelliSense never starts.

`scripts/fix-luals-linux.sh` works around this by downloading the matching
official **Linux x64** build from the upstream
[LuaLS releases](https://github.com/LuaLS/lua-language-server/releases) and
symlinking it over the bundled `.exe` (Node's `spawn()` doesn't care about the
file name on Linux). The version is read from the extension's bundled
`changelog.md`, so the script tracks extension updates automatically.

- Run it via the VS Code task **`FS Lua: Fix Linux LuaLS`**
  (`Terminal > Run Task...`), or directly: `bash scripts/fix-luals-linux.sh`
- The script is idempotent — re-running it after an extension update only
  re-downloads if the bundled LuaLS version changed.
- Downloaded binaries are cached in `.luals/` (gitignored).
- After the script succeeds, run **`FS Lua: Restart Language Server`** from the
  command palette (or reload the window).
