#!/usr/bin/env bash
# mod-link.sh
#
# Manages the live-development symlink for the AdjustableMirrors mod.
#
# Symlinks the repo's modfiles/ into the game's mods folder as
# FS25_AdjustableMirrors. An unpacked mod folder takes precedence over a
# same-named .zip in singleplayer, so edits to modfiles/ are picked up
# directly without re-zipping. (Multiplayer only supports zips - use
# scripts/deploy.sh for that.)
#
# The script is idempotent: run it again and it will only do work that is
# still needed.
#
# Usage:
#   bash scripts/mod-link.sh            # create the symlink (idempotent)
#   bash scripts/mod-link.sh --remove   # remove the symlink so the deployed
#                                       # .zip takes precedence again

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_NAME="FS25_AdjustableMirrors"
MOD_SRC="${REPO_ROOT}/modfiles"

REMOVE=false
for arg in "$@"; do
    case "$arg" in
        --remove) REMOVE=true ;;
        *) echo "ERROR: Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# --- Locate the game's mods folder -------------------------------------------
# The profile lives inside the Proton prefix:
#   <steam>/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/
#       Documents/My Games/FarmingSimulator2025/mods
find_mods_dir() {
    local compatdata_dir prefix profile
    for compatdata_dir in \
        "${HOME}/.local/share/Steam/steamapps/compatdata" \
        /var/mnt/extra/steam/steamapps/compatdata; do
        [[ -d "$compatdata_dir" ]] || continue
        while IFS= read -r prefix; do
            profile="${prefix}/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025"
            if [[ -d "${profile}/mods" ]]; then
                printf '%s\n' "${profile}/mods"
                return 0
            fi
        done < <(find "$compatdata_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    done
    return 1
}

MODS_DIR="$(find_mods_dir || true)"
if [[ -z "$MODS_DIR" ]]; then
    echo "ERROR: Could not find the game's mods folder." >&2
    echo "       Expected: <steam>/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/mods" >&2
    exit 1
fi
MOD_LINK="${MODS_DIR}/${MOD_NAME}"
echo "==> Mods dir: ${MODS_DIR}"

if [[ "$REMOVE" == true ]]; then
    if [[ -L "$MOD_LINK" ]]; then
        rm -f "$MOD_LINK"
        echo "==> Removed mod link: ${MOD_LINK}"
        echo "    The deployed ${MOD_NAME}.zip now takes precedence."
    else
        echo "==> Mod link not present; nothing to remove."
    fi
else
    if [[ -L "$MOD_LINK" ]]; then
        echo "==> Mod already linked: ${MOD_LINK} -> $(readlink "$MOD_LINK")"
    elif [[ -e "$MOD_LINK" ]]; then
        echo "WARNING: ${MOD_LINK} exists and is not a symlink; leaving it alone." >&2
    else
        ln -s "$MOD_SRC" "$MOD_LINK"
        echo "==> Linked mod: ${MOD_LINK} -> ${MOD_SRC}"
    fi
fi
