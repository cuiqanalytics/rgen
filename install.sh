#!/bin/sh
# install.sh — install rgen into ~/.local (no root needed).
#
#   curl -fsSL https://cuiqanalytics.github.io/rgen/install.sh | sh
#
# Re-running it replaces the previous install (upgrade in place). RGEN_URL overrides the
# download location (a file:// URL works too, for testing a local build).
set -eu

repo="cuiqanalytics/rgen"
lib_dir="${HOME}/.local/lib/rgen"
bin_dir="${HOME}/.local/bin"
url="${RGEN_URL:-https://github.com/${repo}/releases/latest/download/rgen-cli-linux-x86_64.tar.gz}"

case "$(uname -s)/$(uname -m)" in
	Linux/x86_64) ;;
	*) echo "rgen ships a Linux x86_64 binary only. On macOS/Windows use Docker:"
	   echo "  docker pull ghcr.io/${repo}"
	   exit 1 ;;
esac

echo "Downloading ${url}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 --retry-delay 2 "$url" | tar xz -C "$tmp"

rm -rf "$lib_dir"
mkdir -p "$(dirname "$lib_dir")"
mv "$tmp/rgen-cli-linux-x86_64" "$lib_dir"

mkdir -p "$bin_dir"
ln -sf "$lib_dir/rgen" "$bin_dir/rgen"

echo "Installed to $lib_dir"
echo "Linked $bin_dir/rgen -> $lib_dir/rgen"

case ":$PATH:" in
	*":$bin_dir:"*) ;;
	*) echo "Add $bin_dir to your PATH (e.g. in ~/.bashrc): export PATH=\"$bin_dir:\$PATH\"" ;;
esac

"$bin_dir/rgen" --version
