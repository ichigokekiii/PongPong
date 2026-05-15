#!/bin/sh

set -e

if [ -z "$EXPANDED_CODE_SIGN_IDENTITY" ] || [ "$CODE_SIGNING_ALLOWED" = "NO" ]; then
  exit 0
fi

APP_FRAMEWORK="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/App.framework"
MANIFEST_PATH="$APP_FRAMEWORK/flutter_assets/NativeAssetsManifest.json"
FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"

if [ ! -f "$MANIFEST_PATH" ] || [ ! -d "$FRAMEWORKS_DIR" ]; then
  exit 0
fi

/usr/bin/python3 - "$MANIFEST_PATH" <<'PY' | while IFS= read -r framework_name; do
import json
import sys

manifest_path = sys.argv[1]
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

names = set()
for per_platform in manifest.get("native-assets", {}).values():
    for asset in per_platform.values():
        if (
            isinstance(asset, list)
            and len(asset) == 2
            and asset[0] == "absolute"
            and isinstance(asset[1], str)
        ):
            framework_path = asset[1]
            framework_dir, _, framework_name = framework_path.partition("/")
            if framework_dir == f"{framework_name}.framework":
                names.add(framework_name)

for name in sorted(names):
    print(name)
PY
  framework_path="$FRAMEWORKS_DIR/$framework_name.framework"
  if [ -d "$framework_path" ]; then
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --preserve-metadata=identifier,flags,runtime "$framework_path"
  fi
done
