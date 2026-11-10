#!/bin/sh
# Install-time build step for macOS/Linux (run by Herdr at `plugin install`,
# cwd = plugin root).
#
# Builds the binary from source with `go`. There is deliberately no prebuilt
# download: the binary is always compiled from the code you installed (see
# specs/006-build-from-source.md). The only network access is Go fetching the
# modules in go.mod, which it checks against go.sum. GOTOOLCHAIN=local stops Go
# from downloading a newer toolchain; an older Go fails with a clear error.
set -eu

BIN="herdr-space-scoped-agents"

root="${HERDR_PLUGIN_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
manifest="$root/herdr-plugin.toml"
out="$root/bin/$BIN"

version="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$manifest" | head -n1)"
[ -n "$version" ] || { echo "cannot read version from $manifest" >&2; exit 1; }

command -v go >/dev/null 2>&1 || {
  echo "ERROR: Go is required to build $BIN (https://go.dev/dl/)" >&2
  exit 1
}

# Append the commit, e.g. 0.6.0+892cdd6, so a box's build can be matched to
# git. Skipped unless the plugin root is itself a git checkout, so a plugin
# dir that merely sits inside another repo (e.g. dotfiles) isn't mislabeled.
if [ -e "$root/.git" ] && sha="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"; then
  version="${version}+${sha}"
fi

mkdir -p "$root/bin"
echo "building $BIN v${version} from source with go..." >&2
( cd "$root" && GOTOOLCHAIN=local go build -trimpath -ldflags "-s -w -X main.version=${version}" -o "$out" . )
echo "built -> $out" >&2
