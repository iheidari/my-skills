#!/usr/bin/env bash
# Non-interactive $EDITOR for expo-release.sh.
#
# expo-release.sh curates copy by opening $EDITOR on a file. This stands in for
# that editor and drops in copy prepared before the run, so nothing blocks on a
# terminal and the Play 500-char loop clears on its first lap.
#
# Env (both required, absolute paths):
#   EXPO_RELEASE_CHANGELOG  CHANGELOG.md section  (Keep a Changelog, keeps (#NN))
#   EXPO_RELEASE_STORE      store copy, <=500 chars, no ticket IDs, no PR numbers
set -euo pipefail

target="${1:?editor-shim: no target file}"

case "$(basename "$target")" in
  changelog.md) src="${EXPO_RELEASE_CHANGELOG:?editor-shim: EXPO_RELEASE_CHANGELOG unset}" ;;
  *)            src="${EXPO_RELEASE_STORE:?editor-shim: EXPO_RELEASE_STORE unset}" ;;
esac

[ -f "$src" ] || { echo "editor-shim: no such file: $src" >&2; exit 1; }
cat "$src" > "$target"
