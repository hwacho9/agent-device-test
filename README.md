# AgentDeviceE2EDemo

A local presentation demo: shared Kotlin business logic, Android Jetpack Compose,
iOS SwiftUI, visual regression, and real-device agent-device exploration/replay.
No backend, real accounts, persistence, shared Compose UI, CI or store deployment.

Demo login: **demo@example.com / demo1234**.

## Current verification
2026-09-07: `bash scripts/run-all-local.sh` passed all 7 stages. Common tests: 6/6;
Android visual: 11/11; iOS visual: 11/11. Both platforms completed an actual
Agent Pass, at least two consecutive deterministic replays and verified MP4s.
See the [final report](docs/FINAL_REPORT.md) for artifact paths, sizes, commands
and limitations, or [implementation status](docs/IMPLEMENTATION_STATUS.md).

## Architecture
`shared/commonMain` owns login, session and profile saves. Native UI adapters call
the same DemoSession. [Architecture](docs/ARCHITECTURE.md).

## Build and run
```sh
bash scripts/check-environment.sh
bash scripts/build-android.sh
bash scripts/install-android.sh
bash scripts/build-ios.sh
bash scripts/install-ios.sh
```
Use Bash for `source scripts/env.sh`. [Build runbook](docs/BUILD_RUNBOOK.md).

## Pinned toolchain
- Kotlin / Compose Compiler plugin 2.4.10
- AGP 9.1.0, Gradle 9.3.1, JDK 17
- Compose BOM 2025.08.01, Activity Compose 1.10.1
- Android API 35, Build Tools 36.0.0
- Xcode 26.6, iPhone 17 Pro / iOS 26.5
- XcodeGen 2.45.3 regenerates `iosApp/project.yml` (generated project included)

- agent-device 0.20.10 (local npm dependency), Node 24.19.0 (existing bundled runtime)
- Compose Screenshot plugin 0.0.1-alpha15; Point-Free SnapshotTesting 1.19.4

SnapshotTesting is a third-party Point-Free library, not an Apple official tool.

## Visual tests
```sh
bash scripts/android-visual.sh record    # explicit reference generation
bash scripts/android-visual.sh validate  # never updates references
bash scripts/ios-visual.sh record
bash scripts/ios-visual.sh validate
```
[Visual runbook](docs/VISUAL_TESTING.md)

## Agent exploration and deterministic replay
```sh
bash scripts/explore-android-e2e.sh
bash scripts/explore-ios-e2e.sh
# Codex continues interactively from snapshots; bootstrap alone is not PASS.
bash scripts/replay-android-e2e.sh
bash scripts/replay-ios-e2e.sh
bash scripts/record-android-clean.sh
bash scripts/record-ios-clean.sh
bash scripts/run-all-local.sh
```
[Agent-device runbook](docs/AGENT_DEVICE_RUNBOOK.md) ·
[Presentation runbook](docs/PRESENTATION_DEMO_RUNBOOK.md)

## Known constraints
- Screenshot plugin is experimental. Baselines are specific to the pinned runtime/toolchain.
- Android helper omits checked; replay verifies the user-facing On/Off state bound to the same shared boolean.
- iOS Toggle interaction targets its native leaf and verifies the stable parent ID/value.
- Explicit agent-device state directory prevents prepare/replay runner ownership conflicts.
- Current-device evidence and fresh-install resets apply only to the dedicated demo app.
- Device commands need native macOS service access outside Codex's filesystem sandbox.

## Evidence
Builds, reports, logs and videos belong under `artifacts/android` and
`artifacts/ios`. Runtime evidence is ignored by Git. Visual reference generation
and validation are separate operations; validation must not modify references.

Generate the offline, local-only evidence dashboard after platform result JSON
exists:

```sh
bash scripts/run-platform-ci.sh android
bash scripts/run-platform-ci.sh ios
./scripts/generate-local-report.sh
./scripts/serve-local-report.sh
```

The dashboard is served at `http://127.0.0.1:8080`. It is ignored by Git and is
never uploaded by CI. The pull-request workflow runs Android and iOS independently,
keeps short-lived PNG/MP4/log/JSON artifacts, publishes the final PNG and MP4 in a
run-specific GitHub prerelease, and embeds their previews/links in one marker
comment. After a successful publication it removes older evidence releases for the
same PR on a best-effort basis. Fork PRs receive read-only build/test execution and
no comment or media upload operation.

[Local HTML report](docs/LOCAL_HTML_REPORT.md) · [CI runbook](docs/CI_RUNBOOK.md) ·
[PR evidence](docs/PR_EVIDENCE.md) · [GitHub setup](docs/GITHUB_SETUP.md) ·
[CI security](docs/CI_SECURITY.md)

[Scenario](docs/E2E_SCENARIO.md) · [OBS](docs/OBS_RECORDING_RUNBOOK.md) ·
[Troubleshooting](docs/TROUBLESHOOTING.md)

The pinned agent-device dev dependency currently has npm audit advisories (one
high, two moderate); details and the reason no forced downgrade was applied are
in docs/TROUBLESHOOTING.md. These packages are not part of either mobile app.
