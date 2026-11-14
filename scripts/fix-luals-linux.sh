#!/usr/bin/env bash
# fix-luals-linux.sh
#
# Workaround for the GIANTS "Farming Simulator IDE Support" VS Code extension
# on Linux: the extension only ships a Windows (PE) build of the LuaLS language
# server, which cannot run on Linux. This script downloads the matching
# official Linux x64 build from the upstream LuaLS GitHub releases and
# symlinks it over the bundled .exe (Node's spawn() uses execvp on Linux, so
# the file name is irrelevant).
#
# The script is idempotent: run it again after an extension update and it will
# re-download only if the bundled LuaLS version changed.
#
# Usage: bash scripts/fix-luals-linux.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUALS_DIR="${REPO_ROOT}/.luals"
EXT_GLOB="${HOME}/.vscode/extensions/giantssoftware.farmingsimulator-ide-*"

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

# --- Check if already fixed -------------------------------------------------
# A fixed target is either a symlink, or a regular file that is a Linux ELF.
if [[ -L "$TARGET" ]]; then
    echo "==> Already fixed (symlink in place): $(readlink "$TARGET")"
    exit 0
fi
if [[ "$(head -c 4 "$TARGET" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]; then
    echo "==> Already fixed (Linux ELF in place)."
    exit 0
fi

# --- Determine bundled LuaLS version ----------------------------------------
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

# --- Download (only if not already cached) -----------------------------------
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

# --- Backup original Windows binary (once) and symlink ------------------------
if [[ ! -f "${TARGET}.win.bak" ]]; then
    cp -p "$TARGET" "${TARGET}.win.bak"
    echo "==> Backed up original Windows binary to ${TARGET}.win.bak"
fi
ln -sf "$LOCAL_BIN" "$TARGET"
echo "==> Symlinked: ${TARGET} -> ${LOCAL_BIN}"

# --- Verify -------------------------------------------------------------------
echo "==> Verifying..."
if "$TARGET" --version; then
    echo "==> Success. Restart the language server in VS Code:"
    echo "       Command Palette -> 'FS Lua: Restart Language Server'"
else
    echo "ERROR: Binary ran but --version failed. See output above." >&2
    exit 1
fi
