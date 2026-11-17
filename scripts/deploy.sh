#!/usr/bin/env bash
# deploy.sh
#
# Zips the modfiles/ folder into FS25_AdjustableMirrors.zip and copies it to
# the game's mods folder.
#
# Why a zip? Multiplayer only supports zip mods - the dev folder symlink that
# fix-luals-linux.sh creates is singleplayer-only (an unpacked mod folder takes
# precedence over a same-named .zip in singleplayer, but is ignored in MP).
# So to test MP you need the zip deployed alongside the dev link.
#
# Usage:
#   bash scripts/deploy.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_NAME="FS25_AdjustableMirrors"
ZIP_NAME="${MOD_NAME}.zip"

# --- Locate the game's mods folder -------------------------------------------
# The profile lives inside the Proton prefix:
#   <steam>/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/
#       Documents/My Games/FarmingSimulator2025/mods
find_mods_dir() {
    local compatdata_dir profile
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
echo "==> Mods dir: ${MODS_DIR}"

# --- Build the zip -----------------------------------------------------------
# Zip the *contents* of modfiles/ (not the folder itself) so the zip root
# contains modDesc.xml directly, as FS expects. Exclude editor/tooling dirs.
cd "${REPO_ROOT}/modfiles"
rm -f "${REPO_ROOT}/${ZIP_NAME}"
zip -r "${REPO_ROOT}/${ZIP_NAME}" . -x '.vscode/*' -x '*.git*'

# --- Deploy to the mods folder -----------------------------------------------
cp -f "${REPO_ROOT}/${ZIP_NAME}" "${MODS_DIR}/${ZIP_NAME}"
echo "==> Deployed: ${MODS_DIR}/${ZIP_NAME}"
echo "==> Also available at: ${REPO_ROOT}/${ZIP_NAME}"

# --- Unpack a clean copy for the Giants Testrunner ----------------------------
# The Testrunner needs an unpacked mod with no extra files (e.g. .vscode/),
# so we unzip the freshly built zip into a gitignored .verify/ folder.
VERIFY_DIR="${REPO_ROOT}/.verify/${MOD_NAME}"
rm -rf "${VERIFY_DIR}"
mkdir -p "${VERIFY_DIR}"
unzip -q "${REPO_ROOT}/${ZIP_NAME}" -d "${VERIFY_DIR}"
echo "==> Unpacked for Testrunner: ${VERIFY_DIR}"
