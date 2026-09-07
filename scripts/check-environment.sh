#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
sw_vers
uname -m
java -version
for tool in adb emulator xcrun xcodebuild node npm git; do command -v "$tool"; done
printf "SDK: %s\n" "$ANDROID_HOME"
ls "$ANDROID_HOME/platforms" "$ANDROID_HOME/build-tools"
adb version
emulator -list-avds
xcodebuild -version
xcrun simctl list runtimes
xcrun simctl list devices available
node --version
npm --version
git --version
if [[ -x ./gradlew ]]; then ./gradlew --version; else echo 'Gradle wrapper: NOT CREATED'; fi
if command -v agent-device >/dev/null; then agent-device --version; else echo 'agent-device: NOT INSTALLED (integration gated after visual tests)'; fi
