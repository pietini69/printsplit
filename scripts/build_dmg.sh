#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_NAME="PrintSplit & Pin"
BUNDLE_NAME="PrintSplitMac"
VERSION="1.0"
DIST_DIR="${PROJECT_DIR}/dist"
STAGE_DIR="/tmp/PrintSplit_Build"

export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"

echo "=========================================================="
echo " Building ${APP_NAME} v${VERSION} Universal DMG"
echo "=========================================================="

# 1. Clean staging and build directories
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}/DerivedData" "${STAGE_DIR}/staging" "${DIST_DIR}"

# 2. Compile Universal Binary (x86_64 + arm64)
echo "==> [1/4] Compiling Universal binary..."
xcodebuild \
    -project "${PROJECT_DIR}/PrintSplitMac.xcodeproj" \
    -scheme "${BUNDLE_NAME}" \
    -configuration Release \
    -derivedDataPath "${STAGE_DIR}/DerivedData" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    build

APP_PATH="${STAGE_DIR}/DerivedData/Build/Products/Release/${BUNDLE_NAME}.app"

if [[ ! -d "${APP_PATH}" ]]; then
    echo "ERROR: Built app bundle not found at ${APP_PATH}"
    exit 1
fi

# Verify Universal Binary
echo "==> Architectures in executable:"
lipo -info "${APP_PATH}/Contents/MacOS/${BUNDLE_NAME}"

# 3. Code sign ad-hoc
echo "==> [2/4] Signing app bundle..."
codesign --force --deep --sign - "${APP_PATH}"

# 4. Prepare DMG Staging
echo "==> [3/4] Preparing DMG staging folder..."
cp -R "${APP_PATH}" "${STAGE_DIR}/staging/${APP_NAME}.app"
ln -s /Applications "${STAGE_DIR}/staging/Applications"

# 5. Create compressed DMG
DMG_OUTPUT="${DIST_DIR}/PrintSplit-${VERSION}.dmg"
rm -f "${DMG_OUTPUT}"

echo "==> [4/4] Creating compressed DMG..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGE_DIR}/staging" -ov -format UDZO "${DMG_OUTPUT}"

echo "=========================================================="
echo " SUCCESS! DMG created at: ${DMG_OUTPUT}"
echo " Size: $(ls -lh "${DMG_OUTPUT}" | awk '{print $5}')"
echo " SHA256: $(shasum -a 256 "${DMG_OUTPUT}" | awk '{print $1}')"
echo "=========================================================="
