#!/bin/bash
# release.sh — builds, signs, notarizes, and packages Agent Pulse for distribution
# Usage: ./scripts/release.sh [version]
# Example: ./scripts/release.sh 1.0.0
#
# Prerequisites:
#   brew install create-dmg
#   Xcode with Developer ID Application certificate
#   Apple ID app-specific password from appleid.apple.com

set -e

VERSION=${1:-$(xcodebuild -project AgentPulse.xcodeproj -target AgentPulse -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | awk '{print $3}')}
BUILD_DIR="build/release"
APP_NAME="AgentPulse"
DMG_NAME="AgentPulse-${VERSION}.dmg"

echo "▶ Building Agent Pulse ${VERSION}..."

# 1. Archive
xcodebuild archive \
    -project AgentPulse.xcodeproj \
    -scheme AgentPulse \
    -configuration Release \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    MARKETING_VERSION="${VERSION}" \
    | xcpretty 2>/dev/null || true

# 2. Export (Developer ID — direct distribution, not App Store)
cat > /tmp/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "${BUILD_DIR}/export" \
    -exportOptionsPlist /tmp/ExportOptions.plist \
    | xcpretty 2>/dev/null || true

APP_PATH="${BUILD_DIR}/export/${APP_NAME}.app"
echo "✓ Archive exported to ${APP_PATH}"

# 3. Notarize (requires APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD env vars)
if [[ -n "$APPLE_ID" && -n "$APPLE_TEAM_ID" && -n "$APPLE_APP_PASSWORD" ]]; then
    echo "▶ Notarizing..."
    ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${BUILD_DIR}/${APP_NAME}.zip"
    xcrun notarytool submit "${BUILD_DIR}/${APP_NAME}.zip" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
    xcrun stapler staple "${APP_PATH}"
    echo "✓ Notarized and stapled"
else
    echo "⚠ Skipping notarization (set APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD to enable)"
fi

# 4. Create DMG
echo "▶ Creating DMG..."
mkdir -p "${BUILD_DIR}/dmg"

create-dmg \
    --volname "Agent Pulse ${VERSION}" \
    --volicon "${APP_PATH}/Contents/Resources/AppIcon.icns" \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "${APP_NAME}.app" 130 190 \
    --app-drop-link 400 190 \
    --background "scripts/dmg_background.png" \
    "${BUILD_DIR}/${DMG_NAME}" \
    "${APP_PATH}" 2>/dev/null || \
create-dmg \
    --volname "Agent Pulse ${VERSION}" \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "${APP_NAME}.app" 130 190 \
    --app-drop-link 400 190 \
    "${BUILD_DIR}/${DMG_NAME}" \
    "${APP_PATH}"

echo ""
echo "✅ Release ready: ${BUILD_DIR}/${DMG_NAME}"
echo ""
echo "Next steps:"
echo "  1. Create GitHub release: gh release create v${VERSION} ${BUILD_DIR}/${DMG_NAME}"
echo "  2. Update Homebrew cask SHA256: shasum -a 256 ${BUILD_DIR}/${DMG_NAME}"
