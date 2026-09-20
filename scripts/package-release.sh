#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
cd "$repo_root"

cache_dir="$(mktemp -d /private/tmp/i-mac-key-build.XXXXXX)"
trap 'rm -rf "$cache_dir"' EXIT

CLANG_MODULE_CACHE_PATH="$cache_dir" SWIFTPM_MODULECACHE_OVERRIDE="$cache_dir" swift build -c release --disable-sandbox

output_dir="$repo_root/dist"
app_dir="$output_dir/i-mac-key.app"
archive="$output_dir/i-mac-key.zip"
checksum="$output_dir/SHA256SUMS.txt"

if [[ -e "$app_dir" || -e "$archive" || -e "$checksum" ]]; then
  print -u2 "dist/ already contains a release artifact. Remove it before packaging again."
  exit 1
fi

mkdir -p "$app_dir/Contents/MacOS"
cp .build/release/i-mac-key "$app_dir/Contents/MacOS/IMacKey"
cp Resources/Info.plist "$app_dir/Contents/Info.plist"
codesign --force --sign - "$app_dir"
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$archive"
shasum -a 256 "$archive" > "$checksum"
