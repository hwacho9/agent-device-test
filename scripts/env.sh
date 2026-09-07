#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${DEMO_JAVA_HOME:-}" ]]; then
    export JAVA_HOME="$DEMO_JAVA_HOME"
elif [[ -x /usr/libexec/java_home ]]; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
elif [[ -n "${JAVA_HOME:-}" ]]; then
    export JAVA_HOME
else
    java_binary="$(command -v java)"
    export JAVA_HOME="$(cd "$(dirname "$java_binary")/.." && pwd)"
fi
if [[ -n "${DEMO_ANDROID_SDK:-}" ]]; then
    demo_android_sdk="$DEMO_ANDROID_SDK"
elif [[ -n "${ANDROID_HOME:-}" ]]; then
    demo_android_sdk="$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    demo_android_sdk="$ANDROID_SDK_ROOT"
else
    demo_android_sdk="$HOME/Library/Android/sdk"
fi
export ANDROID_HOME="$demo_android_sdk"
export ANDROID_SDK_ROOT="$demo_android_sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ROOT/.tools/android-cli/cmdline-tools/bin:$PATH"
export DEMO_AVD="${DEMO_AVD:-AgentDeviceE2EDemo_API35}"
export DEMO_IOS_UDID="${DEMO_IOS_UDID:-2D1249E5-37FA-4800-A45E-9A7D1ABD651F}"
export ANDROID_APP_ID=com.example.agentdevicee2edemo
export IOS_APP_ID=com.example.agentdevicee2edemo.ios
# Use the verified bundled Node if the shell's Node is too old. No global changes.
if ! node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>22||a===22&&b>=12?0:1)' 2>/dev/null; then
    demo_node_dir="${DEMO_NODE_DIR:-$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin}"
    if [[ -x "$demo_node_dir/node" ]]; then export PATH="$demo_node_dir:$PATH"; fi
fi
export PATH="$ROOT/node_modules/.bin:$PATH"
# Explicit state directory keeps prepare/replay/follow-up commands on one daemon.
# Otherwise agent-device 0.20.10 creates an isolated one-shot replay daemon.
export AGENT_DEVICE_STATE_DIR="${AGENT_DEVICE_STATE_DIR:-$HOME/.agent-device}"
