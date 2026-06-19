#!/bin/bash
# ╔══════════════════════════════════════╗
# ║  elmahdi_travel_suite — Build Script ║
# ╚══════════════════════════════════════╝

set -e
echo "🚀 Building elmahdi_travel_suite..."

echo ""
echo "📦 Step 1: Installing dependencies..."
flutter pub get

echo ""
echo "⚙️  Step 2: Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Step 3: Checking for issues..."
flutter analyze --no-fatal-infos

echo ""
echo "🎉 Build ready! Run with:"
echo "   flutter run"
