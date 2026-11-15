#!/usr/bin/env bash
# fix-luals-linux.sh
#
# Linux compatibility fixes for the GIANTS "Farming Simulator IDE Support"
# VS Code extension, which is built with Windows conventions in mind:
#
#   1. LuaLS language server: the extension only ships a Windows (PE) build,
#      which cannot run on Linux. This script downloads the matching official
#      Linux x64 build from the upstream LuaLS GitHub releases and symlinks
#      it over the bundled .exe (Node's spawn() uses execvp on Linux, so the
#      file name is irrelevant).
#
#   2. My Games profile: the extension's game log watcher looks for the FS
#      profile in $HOME/Documents/My Games/FarmingSimulator<year> (a Windows
#      convention). On Linux with Steam/Proton the profile lives inside the
#      Proton prefix, so a directory with file symlinks is created to satisfy
#      the lookup.
#
#   3. Mod link: modfiles/ is symlinked into the game's mods folder as
#      FS25_AdjustableMirrors for live development (an unpacked mod folder
#      takes precedence over a same-named .zip in-game).
#
# The script is idempotent: run it again after an extension update and it will
# only do work that is still needed.
#
# Usage:
#   bash scripts/fix-luals-linux.sh               # apply all fixes (idempotent)
#   bash scripts/fix-luals-linux.sh --remove-mod-link
#       Remove the FS25_AdjustableMirrors mod symlink so the deployed .zip
#       takes precedence again (needed for playing online servers that
#       require the mod).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUALS_DIR="${REPO_ROOT}/.luals"
EXT_GLOB="${HOME}/.vscode/extensions/giantssoftware.farmingsimulator-ide-*"

REMOVE_MOD_LINK=false
for arg in "$@"; do
    case "$arg" in
        --remove-mod-link) REMOVE_MOD_LINK=true ;;
        *) echo "ERROR: Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

echo "==> Locating Farming Simulator IDE extension..."
ext_dirs=()
for d in ${EXT_GLOB}; do
    [[ -d "$d" ]] && ext_dirs+=("$d")
done
if [[ ${#ext_dirs[@]} -eq 0 ]]; then
    echo "ERROR: Could not find the farmingsimulator-ide extension in ~/.vscode/extensions/" >&2
    echo "       Install 'Farming Simulator IDE Support' (GIANTSSoftware) first." >&2
    exit 1
fi
# If multiple versions are installed, use the newest (last in glob order is not
# guaranteed, so pick by version suffix).
EXT_DIR="$(printf '%s\n' "${ext_dirs[@]}" | sort -V | tail -n1)"
BIN_DIR="${EXT_DIR}/server/lua-language-server/bin"
TARGET="${BIN_DIR}/lua-language-server.exe"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: Expected language server binary not found at:" >&2
    echo "       ${TARGET}" >&2
    exit 1
fi

# --- LuaLS fix (skip if already done) ----------------------------------------
LUALS_FIXED=false
if [[ -L "$TARGET" ]]; then
    echo "==> LuaLS already fixed (symlink in place): $(readlink "$TARGET")"
    LUALS_FIXED=true
elif [[ "$(head -c 4 "$TARGET" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]; then
    echo "==> LuaLS already fixed (Linux ELF in place)."
    LUALS_FIXED=true
fi

if [[ "$LUALS_FIXED" == false ]]; then
    # --- Determine bundled LuaLS version ------------------------------------
    CHANGELOG="${EXT_DIR}/server/lua-language-server/changelog.md"
    if [[ ! -f "$CHANGELOG" ]]; then
        echo "ERROR: Could not find bundled LuaLS changelog at:" >&2
        echo "       ${CHANGELOG}" >&2
        exit 1
    fi
    VERSION="$(grep -m1 -E '^## [0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG" | sed -E 's/^## ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
    if [[ -z "$VERSION" ]]; then
        echo "ERROR: Could not parse LuaLS version from ${CHANGELOG}" >&2
        exit 1
    fi
    echo "==> Extension bundles LuaLS ${VERSION}"

    # --- Download (only if not already cached) -------------------------------
    mkdir -p "$LUALS_DIR"
    LOCAL_BIN="${LUALS_DIR}/${VERSION}/bin/lua-language-server"
    URL="https://github.com/LuaLS/lua-language-server/releases/download/${VERSION}/lua-language-server-${VERSION}-linux-x64.tar.gz"

    if [[ -x "$LOCAL_BIN" ]]; then
        echo "==> LuaLS ${VERSION} already cached in .luals/"
    else
        echo "==> Downloading ${URL}"
        curl -fL --retry 3 -o "${LUALS_DIR}/lua-language-server-${VERSION}.tar.gz" "$URL"
        mkdir -p "${LUALS_DIR}/${VERSION}"
        tar -xzf "${LUALS_DIR}/lua-language-server-${VERSION}.tar.gz" -C "${LUALS_DIR}/${VERSION}"
        rm -f "${LUALS_DIR}/lua-language-server-${VERSION}.tar.gz"
        chmod +x "$LOCAL_BIN"
    fi

    # --- Backup original Windows binary (once) and symlink --------------------
    if [[ ! -f "${TARGET}.win.bak" ]]; then
        cp -p "$TARGET" "${TARGET}.win.bak"
        echo "==> Backed up original Windows binary to ${TARGET}.win.bak"
    fi
    ln -sf "$LOCAL_BIN" "$TARGET"
    echo "==> Symlinked: ${TARGET} -> ${LOCAL_BIN}"

    # --- Verify ---------------------------------------------------------------
    echo "==> Verifying..."
    if "$TARGET" --version; then
        echo "==> LuaLS fix successful."
    else
        echo "ERROR: Binary ran but --version failed. See output above." >&2
        exit 1
    fi
fi

# --- My Games profile link -----------------------------------------------------
# The extension's game log watcher looks for the FS profile in
# $HOME/Documents/My Games/FarmingSimulator<year> (Windows convention).
# On Linux with Steam/Proton the profile lives inside the Proton prefix:
#   <steam library>/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/
#       Documents/My Games/FarmingSimulator<year>
#
# Note: the watcher filters entries with Dirent.isDirectory(), which is FALSE
# for a symlink to a directory. So we cannot simply symlink the profile dir;
# instead we create a real directory and symlink the individual files the
# watcher needs (game.xml + the log file it names).
echo ""
echo "==> Checking My Games profile link..."
MY_GAMES_DIR="${HOME}/Documents/My Games"

find_profile() {
    # Search Steam compatdata dirs for a FarmingSimulator profile.
    local compatdata_dir prefix profile
    for compatdata_dir in \
        "${HOME}/.local/share/Steam/steamapps/compatdata" \
        /var/mnt/extra/steam/steamapps/compatdata; do
        [[ -d "$compatdata_dir" ]] || continue
        while IFS= read -r prefix; do
            profile="${prefix}/pfx/drive_c/users/steamuser/Documents/My Games"
            if [[ -d "$profile" ]]; then
                # Pick the newest FarmingSimulator* profile dir
                local fs_profiles
                fs_profiles=( "$profile"/FarmingSimulator* )
                if [[ ${#fs_profiles[@]} -gt 0 && -d "${fs_profiles[0]}" ]]; then
                    printf '%s\n' "${fs_profiles[-1]}"
                    return 0
                fi
            fi
        done < <(find "$compatdata_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    done
    return 1
}

PROFILE_SRC="$(find_profile || true)"
if [[ -z "$PROFILE_SRC" ]]; then
    echo "    No FarmingSimulator profile found in Steam compatdata dirs."
    echo "    (Only needed for the game log viewer; safe to ignore.)"
else
    PROFILE_NAME="$(basename "$PROFILE_SRC")"
    PROFILE_LINK="${MY_GAMES_DIR}/${PROFILE_NAME}"

    # A plain symlink to the profile dir is useless (isDirectory() is false
    # for symlinks), so replace one if an earlier version of this script made it.
    if [[ -L "$PROFILE_LINK" ]]; then
        rm -f "$PROFILE_LINK"
    fi

    mkdir -p "$MY_GAMES_DIR"
    if [[ ! -d "$PROFILE_LINK" ]]; then
        mkdir "$PROFILE_LINK"
    fi

    # Symlink the files the log watcher reads: game.xml (names the log file)
    # and the log file itself.
    linked=0
    for f in game.xml log.txt; do
        if [[ -f "${PROFILE_SRC}/${f}" && ! -e "${PROFILE_LINK}/${f}" ]]; then
            ln -s "${PROFILE_SRC}/${f}" "${PROFILE_LINK}/${f}"
            linked=1
        fi
    done
    if [[ "$linked" -eq 1 ]]; then
        echo "    Linked profile files into ${PROFILE_LINK}"
    else
        echo "    Already linked: ${PROFILE_LINK}"
    fi

    # --- Mod symlink for live development --------------------------------------
    # Symlink the repo's modfiles/ into the game's mods folder as
    # FS25_AdjustableMirrors. An unpacked mod folder takes precedence over a
    # same-named .zip in-game, so edits to modfiles/ are picked up directly.
    MODS_DIR="${PROFILE_SRC}/mods"
    MOD_LINK="${MODS_DIR}/FS25_AdjustableMirrors"
    MOD_SRC="${REPO_ROOT}/modfiles"
    if [[ -d "$MODS_DIR" ]]; then
        if [[ "$REMOVE_MOD_LINK" == true ]]; then
            if [[ -L "$MOD_LINK" ]]; then
                rm -f "$MOD_LINK"
                echo "    Removed mod link: ${MOD_LINK}"
                echo "    The deployed FS25_AdjustableMirrors.zip now takes precedence."
            else
                echo "    Mod link not present; nothing to remove."
            fi
        elif [[ -L "$MOD_LINK" ]]; then
            echo "    Mod already linked: ${MOD_LINK} -> $(readlink "$MOD_LINK")"
        elif [[ -e "$MOD_LINK" ]]; then
            echo "    WARNING: ${MOD_LINK} exists and is not a symlink; leaving it alone."
        else
            ln -s "$MOD_SRC" "$MOD_LINK"
            echo "    Linked mod: ${MOD_LINK} -> ${MOD_SRC}"
        fi
    else
        echo "    WARNING: mods folder not found at ${MODS_DIR}; skipping mod link."
    fi
fi

echo ""
echo "==> Done. If you changed settings or the profile link, restart the language server:"
echo "       Command Palette -> 'FS Lua: Restart Language Server'"
