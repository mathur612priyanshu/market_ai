#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not available in PATH."
  echo "Install Flutter, reopen Terminal, and run this script again."
  exit 1
fi

if [ ! -d android ] || [ ! -d ios ]; then
  echo "Generating Android and iOS platform folders..."
  flutter create --platforms=android,ios --org com.marketai --project-name market_ai .
fi

flutter pub get
flutter run
