# Implementation status

2026-09-07: User approved implementation and dependency installation.

## Environment
- macOS 26.4.1, Apple Silicon arm64.
- Android Studio AI-261.26222.65.2613.16025427 (2026.1.3).
- Project JDK: Temurin 17.0.12; default shell still uses JDK 11.
- SDK: `$HOME/Library/Android/sdk`; Android API 35.
- Android Emulator 37.1.11; adb 37.0.1.
- Xcode 26.6 (17F113); iOS 26.5 runtime installed.
- Default Node 22.9.0 is insufficient; scripts select existing bundled Node 24.19.0.

## Gates
- A: PASS. API 35 SDK, Build Tools 36.0.0, dedicated ARM64 AVD.
- B: PASS. 6 common tests, Android compile, iOS Simulator framework compile.
- C: PASS. APK fresh install and UI flow; later real agent-device runs also passed.
- D: PASS. Shared embedded in final .app; fresh install and XCTest UI flow.
- Android visual: PASS, 11 previews with reviewed references.
- iOS visual: PASS, 11 snapshots using host-window rendering.
- Agent Pass: PASS on Android and iOS, actual successful sessions recorded.
- Deterministic replay: at least 2 consecutive successful runs per platform.
- run-all-local.sh: PASS, all 7 stages, see artifacts/run-all-final.log.
- Clean videos: PASS. Android 29.856 seconds / 161,541 bytes; iOS 21.680 seconds / 2,728,938 bytes. Full decode and sampled visual review passed.

## Resolved integration issues
- Emulator auto GPU backend stalled; explicit SwiftShader restored stable execution.
- iOS Toggle container center was a no-op. Use a separate label and native leaf switch.
- Android helper omits checked: visible On/Off is bound to the same shared state.
- is hidden is not an absent-element assertion: full JSON snapshot asserts no login.error.
- Implicit replay daemon caused runner/device ownership conflict: set explicit state directory.
- iOS decoration ancestry changes between snapshots: retain stable toggle-parent identity.

## Constraints
Kotlin compatibility documentation lists Xcode 26.4 for Kotlin 2.4.10;
Xcode 26.6 framework compilation, final app build, snapshots and runtime E2E passed locally.
CoreSimulator and Emulator need execution outside the desktop filesystem sandbox.
No OBS operations. No agent-device integration before both visual suites pass.
