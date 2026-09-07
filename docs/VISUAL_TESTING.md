# Visual regression

Both suites cover 11 states: Login Default/Error/Dark/Large Font; Home Default/Dark;
Profile Default/Reminder Enabled/Saved/Dark/Large Font.
Fixtures are local values supplied to pure screens, without navigation, DI or network.

## Android
Uses the experimental official Compose Preview Screenshot plugin 0.0.1-alpha15,
AGP 9.1.0, Kotlin/Compose Compiler 2.4.10 and JDK 17. The plugin is applied only
to the Android app, not the KMP shared module. Previews use 412×850 dp, en locale,
fixed day/night mode, and font scale 1.0 or 1.5.

```sh
bash scripts/android-visual.sh record
bash scripts/android-visual.sh validate
```
The actual tasks, verified from `:androidApp:tasks --all`, are
`:androidApp:updateDebugScreenshotTest` and `:androidApp:validateDebugScreenshotTest`.

- Source references: androidApp/src/screenshotTestDebug/reference
- Actual renders: androidApp/build/outputs/screenshotTest-results/preview/debug/rendered
- HTML: androidApp/build/reports/screenshotTest/preview/debug/index.html
- Exported evidence: artifacts/android/visual/{reference,actual,diff,report}
- Exported HTML: artifacts/android/visual/report/index.html

## iOS
Point-Free SnapshotTesting 1.19.4 is a third-party library, not an Apple tool.
It is pinned with SPM. A separate XCTest target hosts SwiftUI views in
UIHostingController on iPhone 17 Pro / iOS 26.5. Image layout is fixed to the
library's iPhone13 configuration. Locale is en_US_POSIX, timezone UTC, dynamic
size large or accessibility1, and color scheme light/dark.

```sh
bash scripts/ios-visual.sh record
bash scripts/ios-visual.sh validate
```
Recording explicitly uses `.all` and checks that the library reports a recorded
snapshot. That only establishes reference generation, not validation success.
Validation uses `.never` and fails on missing references or differences.
The scripts check reference file count and before/after digests for validation.

- Source references: iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__
- Exported references: artifacts/ios/visual/reference
- Results/attachments: artifacts/ios/visual/xcresult
- Diff export directory: artifacts/ios/visual/diff

Rendering uses the host window hierarchy so iOS 26 visual effects and switch
thumbs can appear in snapshots. Baselines are reviewed visually as well as
compared automatically. Validation requires 99.5% raw pixel precision. This
absorbs cross-runner text antialiasing and one-byte color conversion differences
while preserving failures for visible regressions. Perceptual comparison is not
used because Core Image color-profile conversion varies across hosted runners.

## Baseline policy
Only an explicit record command may change references. Review all 11 states
before accepting them. Runtime screenshots/videos/logs are ignored by Git;
reviewed test reference PNGs belong with source. An empty diff directory means
no diff was emitted; never manufacture a successful-looking diff artifact.
