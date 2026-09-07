# Mobile CI runbook

`.github/workflows/mobile-e2e.yml` runs for opened, synchronized, and reopened pull
requests and for manual dispatch. Concurrency cancels the older run for the same
PR or ref. Android and iOS jobs are independent so one failure does not discard
the other platform's evidence.

The Android job uses JDK 17, Node 24.19.0, the locked npm dependency, API 35, and
an x86_64 Google APIs emulator. It runs common tests, Compose screenshot
validation, the existing APK build, fresh install, reviewed `.ad` replay,
assertions, and recording through `run-platform-ci.sh android`.

The iOS job uses the `macos-26` hosted runner and chooses an actually available
iPhone simulator. It runs common tests, SnapshotTesting validation, the final
`.app` build with embedded `Shared.framework`, then boot → install → prepare
iOS runner → reviewed replay → assertions → recording through
`run-platform-ci.sh ios`.

Neither job invokes baseline record/update. Each always collects a five-day
artifact:

- `android-e2e-evidence`: `android.json`, PNG/MP4, app/runner/result logs, visual
  PNG/log evidence, and common JUnit XML.
- `ios-e2e-evidence`: `ios.json`, PNG/MP4, app/runner/result logs, visual PNG/log
  evidence, and the bounded iOS build log.

HTML, APK, `.app`, full build trees, DerivedData, and full xcresult bundles are
excluded. Artifact upload is post-processing and cannot convert a failed core step
to PASS.

Local reproduction:

```bash
npm ci
bash scripts/run-platform-ci.sh android
bash scripts/run-platform-ci.sh ios
```

Diagnose the first failure recorded in JSON, then inspect its `log`. Classify it
as build, visual, install/device, agent-device/selector, recording, or publishing.
Fix the smallest responsible layer and rerun locally. Do not update baselines,
remove assertions, or introduce long sleeps to clear CI.
