#!/bin/bash
# Build OmniClient Release APK

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Building OmniClient Release APK                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Configuration:${NC}"
echo "  App Name:   OmniClient"
echo "  Domain:     zeion.online"
echo "  API:        https://api.zeion.online"
echo "  LiveKit:    wss://livekit.zeion.online"
echo ""

echo -e "${YELLOW}Step 1: Clean previous build...${NC}"
flutter clean || true

echo ""
echo -e "${YELLOW}Step 2: Get dependencies...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}Step 3: Building release APK...${NC}"
flutter build apk --release --dart-define-from-file=.env

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Build Complete!                                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}APK Location:${NC} $APK_PATH"
    echo -e "${GREEN}APK Size:${NC} $APK_SIZE"
    echo ""
    echo "📱 Install to device:"
    echo "   flutter install --release"
    echo ""
    echo "📤 Or copy APK:"
    echo "   cp $APK_PATH ~/Desktop/OmniClient.apk"
else
    echo -e "${YELLOW}⚠ APK not found at expected location${NC}"
fi

echo ""
echo -e "${BLUE}Ready for demo! 🚀${NC}"
