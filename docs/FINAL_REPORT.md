# 구현 완료 보고서 — 2026-09-07

승인 이후 구현했으며, 아래 PASS는 이 Mac의 실제 실행 결과입니다.
`bash scripts/run-all-local.sh`의 7개 단계가 모두 PASS했습니다.
전체 로그: [run-all-final.log](../artifacts/run-all-final.log).

## Environment

| 항목 | 실제 값 |
|---|---|
| macOS | 26.4.1 (25E253), arm64 |
| Android Studio | 2026.1.3 / AI-261.26222.65.2613.16025427 |
| JDK | 프로젝트 Temurin 17.0.12; 기본 셸 11.0.24 |
| Kotlin | 2.4.10 |
| AGP / Gradle | 9.1.0 / 9.3.1 |
| Android SDK | API 35, Build Tools 36.0.0 |
| Android Emulator / adb | 37.1.11 / 37.0.1 |
| AVD | AgentDeviceE2EDemo_API35, ARM64, emulator-5580 |
| Xcode | 26.6 (17F113) |
| iOS Runtime | 26.5, iPhone 17 Pro |
| Node.js | 스크립트 24.19.0; 기본 셸 22.9.0 |
| agent-device | 로컬 npm 0.20.10 |
| Visual libraries | Compose Screenshot 0.0.1-alpha15 / SnapshotTesting 1.19.4 |

SDK 경로: `/Users/chosunghwa/Library/Android/sdk`.
iOS UDID: `2D1249E5-37FA-4800-A45E-9A7D1ABD651F`.
환경 원본: [check.log](../artifacts/environment/check.log).

## Build Result

| 대상 | 명령 | 결과 | 실제 산출물 |
|---|---|---|---|
| commonMain tests | `./gradlew :shared:testAndroidHostTest` | PASS, 6/6 | [JUnit XML](../shared/build/test-results/testAndroidHostTest/TEST-com.example.agentdevicee2edemo.shared.DemoSessionTest.xml) |
| Android APK | `bash scripts/build-android.sh` | PASS | [APK](../artifacts/android/build/androidApp-debug.apk), 10,712,544 bytes |
| KMP iOS framework | `./gradlew :shared:linkDebugFrameworkIosSimulatorArm64` | PASS | [Shared.framework](../shared/build/bin/iosSimulatorArm64/debugFramework/Shared.framework) |
| iOS .app | `bash scripts/build-ios.sh` | PASS | [AgentDeviceE2EDemo.app](../artifacts/ios/build/DerivedData/Build/Products/Debug-iphonesimulator/AgentDeviceE2EDemo.app), 1,685,060 bytes |

`.app` 크기는 내부 파일 크기의 합입니다. 최종 `.app/Frameworks/Shared.framework/Shared` 존재를 확인했습니다.
Xcode 빌드에서 `:shared:embedAndSignAppleFrameworkForXcode`가 실행되었습니다.
Android fresh install + adb UI smoke, iOS fresh install + XCTest UI smoke도 PASS했습니다.

## Visual Test Result

| 플랫폼 | 결과 | Reference | Diff/Report |
|---|---|---|---|
| Android | PASS, 11/11 | [reference](../androidApp/src/screenshotTestDebug/reference/) | [HTML report](../artifacts/android/visual/report/index.html), [actual](../artifacts/android/visual/actual/) |
| iOS | PASS, 11/11 | [Snapshots](../iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/) | [xcresult](../artifacts/ios/visual/xcresult/validate-20260907T075306Z-2633.xcresult) |

Login/Home/Profile, 오류, 저장 완료, reminder 활성화, dark mode, large font를 포함합니다.
reference 생성과 validation은 별도 명령이며 validation 전후 reference SHA-256이 동일합니다.
PASS 실행에는 실패 diff가 생성되지 않습니다. iOS는 실제 host-window 렌더링을 사용합니다.

## Runtime E2E Result

| 플랫폼 | Agent Pass | Replay 1 | Replay 2 | Video | Screenshot |
|---|---|---|---|---|---|
| Android | PASS | PASS: 074855Z-96246 | PASS: 074934Z-97404 | [MP4](../artifacts/android/runtime/android-clean-e2e.mp4), 29.856 s / 161,541 bytes | [PNG](../artifacts/android/runtime/android-final.png) |
| iOS | PASS | PASS: 074900Z-96381 | PASS: 074931Z-97220 | [MP4](../artifacts/ios/runtime/ios-clean-e2e.mp4), 21.680 s / 2,728,938 bytes | [PNG](../artifacts/ios/runtime/ios-final.png) |

Replay 폴더 접두사는 `20260907T`입니다. 각 플랫폼의 `artifacts/<platform>/runtime/runs/`에서 확인할 수 있습니다.
최종 녹화도 별도 fresh-install replay에서 PASS했습니다:
[Android](../artifacts/android/runtime/runs/20260907T075431Z-4304/),
[iOS](../artifacts/ios/runtime/runs/20260907T075430Z-4245/).

Codex가 실제 snapshot을 읽고 조작한 Agent Pass 원본은 각 runtime의
`agent-pass-original.ad`이며, 검토한 canonical 시나리오는
[e2e/android](../e2e/android/login-profile-save.ad), [e2e/ios](../e2e/ios/login-profile-save.ad)입니다.
`explore-*.sh`는 새 탐색 세션을 시작하며 그 자체로 AI 탐색 완료를 주장하지 않습니다.

검증 흐름은 로그인 → Home → Profile → reminder OFF→ON → Save → Saved입니다.
Android는 실제 Switch와 같은 공유 상태에 바인딩된 On 표시를 검증하고,
iOS는 native leaf switch를 조작한 뒤 stable parent ID의 value=1을 검증합니다.
최종 JSON에서 필수 요소와 로그인 오류의 부재를 확인합니다.

MP4 전체를 ffmpeg로 디코딩해 오류가 없음을 확인했고, 1초 간격 프레임을 시각 검수했습니다.
입력, 화면 이동, 토글 변경, Saved가 보입니다. 발표용 영상에는 별도 사본에 읽기 시간을 추가했으며,
canonical `.ad`와 상태 검증은 유지했습니다. 영상 종료 후 screenshot을 저장해 화면 정규화 영향을 피했습니다.
OBS 설치·조작은 수행하지 않았으며 수동 녹화 runbook과 위 백업 MP4를 준비했습니다.

## Identifiers

- Android applicationId: `com.example.agentdevicee2edemo`
- Android APK: `artifacts/android/build/androidApp-debug.apk`
- iOS bundle identifier: `com.example.agentdevicee2edemo.ios`
- iOS scheme: `AgentDeviceE2EDemo`
- iOS .app: `artifacts/ios/build/DerivedData/Build/Products/Debug-iphonesimulator/AgentDeviceE2EDemo.app`
- KMP framework: `Shared`
- KMP integration method: Direct Integration (`embedAndSignAppleFrameworkForXcode`), CocoaPods 미사용
- UI: Android Jetpack Compose / iOS SwiftUI, 공통 로그인·프로필 로직은 `DemoSession`

## Changed Files

초기 빈 프로젝트에 아래 파일을 생성했습니다. 로컬 빌드·로그·영상과 의존성 캐시는 Git에서 제외했습니다.
커밋은 생성하지 않았습니다.

```text
.gitignore
AGENTS.md
README.md
androidApp/build.gradle.kts
androidApp/src/main/AndroidManifest.xml
androidApp/src/main/kotlin/com/example/agentdevicee2edemo/MainActivity.kt
androidApp/src/main/kotlin/com/example/agentdevicee2edemo/Screens.kt
androidApp/src/main/res/values/styles.xml
androidApp/src/screenshotTest/kotlin/com/example/agentdevicee2edemo/ScreenPreviews.kt
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/HomeDark_HomeDark_7391de9c_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/HomeDefault_HomeDefault_0d105881_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/LoginDark_LoginDark_3cf542ca_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/LoginDefault_LoginDefault_250d17b3_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/LoginError_LoginError_5bcca94e_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/LoginLargeFont_LoginLargeFont_99911aaa_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/ProfileDark_ProfileDark_f19228a6_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/ProfileDefault_ProfileDefault_fef794da_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/ProfileLargeFont_ProfileLargeFont_bb62fd0f_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/ProfileReminderEnabled_ProfileReminderEnabled_be7f3457_0.png
androidApp/src/screenshotTestDebug/reference/com/example/agentdevicee2edemo/ScreenPreviewsKt/ProfileSaved_ProfileSaved_1d0e4abb_0.png
artifacts/presentation/README.md
build.gradle.kts
docs/AGENT_DEVICE_RUNBOOK.md
docs/ARCHITECTURE.md
docs/BUILD_RUNBOOK.md
docs/E2E_SCENARIO.md
docs/FINAL_REPORT.md
docs/IMPLEMENTATION_STATUS.md
docs/OBS_RECORDING_RUNBOOK.md
docs/PRESENTATION_DEMO_RUNBOOK.md
docs/TROUBLESHOOTING.md
docs/VISUAL_TESTING.md
e2e/android/login-profile-save.ad
e2e/ios/login-profile-save.ad
gradle.properties
gradle/libs.versions.toml
gradle/wrapper/gradle-wrapper.jar
gradle/wrapper/gradle-wrapper.properties
gradlew
gradlew.bat
iosApp/AgentDeviceE2EDemo.xcodeproj/project.pbxproj
iosApp/AgentDeviceE2EDemo.xcodeproj/project.xcworkspace/contents.xcworkspacedata
iosApp/AgentDeviceE2EDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
iosApp/AgentDeviceE2EDemo.xcodeproj/xcshareddata/xcschemes/AgentDeviceE2EDemo.xcscheme
iosApp/AgentDeviceE2EDemo/AgentDeviceE2EDemoApp.swift
iosApp/AgentDeviceE2EDemo/Screens.swift
iosApp/AgentDeviceE2EDemoSnapshotTests/ScreenSnapshotTests.swift
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/HomeDark.HomeDark.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/HomeDefault.HomeDefault.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/LoginDark.LoginDark.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/LoginDefault.LoginDefault.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/LoginError.LoginError.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/LoginLargeFont.LoginLargeFont.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/ProfileDark.ProfileDark.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/ProfileDefault.ProfileDefault.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/ProfileLargeFont.ProfileLargeFont.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/ProfileReminderEnabled.ProfileReminderEnabled.png
iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/ProfileSaved.ProfileSaved.png
iosApp/AgentDeviceE2EDemoUITests/SmokeTests.swift
iosApp/project.yml
package-lock.json
package.json
scripts/android-smoke.py
scripts/android-visual.sh
scripts/boot-android.sh
scripts/boot-ios.sh
scripts/build-android.sh
scripts/build-ios.sh
scripts/check-environment.sh
scripts/env.sh
scripts/explore-android-e2e.sh
scripts/explore-ios-e2e.sh
scripts/export-android-visual.py
scripts/install-android.sh
scripts/install-ios.sh
scripts/ios-visual.sh
scripts/prepare-ios-agent-device.sh
scripts/record-android-clean.sh
scripts/record-ios-clean.sh
scripts/reference-digest.py
scripts/replay-android-e2e.sh
scripts/replay-e2e.py
scripts/replay-ios-e2e.sh
scripts/reset-android-demo.sh
scripts/reset-ios-demo.sh
scripts/run-all-local.sh
scripts/smoke-ios.sh
settings.gradle.kts
shared/build.gradle.kts
shared/src/androidMain/kotlin/.gitkeep
shared/src/commonMain/kotlin/com/example/agentdevicee2edemo/shared/DemoSession.kt
shared/src/commonTest/kotlin/com/example/agentdevicee2edemo/shared/DemoSessionTest.kt
shared/src/iosMain/kotlin/.gitkeep
```

## Commands Executed

아래는 실제 실행한 주요 명령입니다. Gradle/agent-device 직접 실행 전 Bash에서 `source scripts/env.sh`를 사용했습니다.
개별 agent-device 액션과 실행 옵션은 각 replay 폴더의 `replay.log`에 보존되어 있습니다.

```bash
bash scripts/check-environment.sh
source scripts/env.sh
./gradlew --version
./gradlew :shared:testAndroidHostTest
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
bash scripts/build-android.sh
bash scripts/install-android.sh
python3 scripts/android-smoke.py
bash scripts/build-ios.sh
bash scripts/install-ios.sh
bash scripts/smoke-ios.sh
bash scripts/android-visual.sh record
bash scripts/android-visual.sh validate
bash scripts/ios-visual.sh record
bash scripts/ios-visual.sh validate
bash scripts/prepare-ios-agent-device.sh
bash scripts/replay-android-e2e.sh
bash scripts/replay-ios-e2e.sh
bash scripts/record-android-clean.sh
bash scripts/record-ios-clean.sh
bash scripts/run-all-local.sh
```

추가로 agent-device CLI help/doctor, npm audit, SDK/Simulator 조사, ffprobe 메타데이터 조회와 ffmpeg 디코딩·프레임 검수를 실행했습니다.
일부 초기 실패 로그도 보존했습니다. runner 소유권, emulator GPU, iOS toggle 대상 문제는 수정 후 재검증했습니다.

## Blockers

필수 구현·로컬 검증의 남은 blocker는 없습니다.

- agent-device 개발 의존성에 npm audit high 1개, moderate 2개가 남아 있습니다. 모바일 앱에는 포함되지 않습니다. 강제 수정은 agent-device 다운그레이드를 제안하므로 적용하지 않았습니다. [상세](TROUBLESHOOTING.md).
- Kotlin 문서의 Xcode 호환 목록은 26.4이나, 이 Mac의 26.6에서 framework/app/visual/runtime 검증을 완료했습니다. 다른 환경의 동작까지 보장하는 결과는 아닙니다.
- reference는 현재 고정한 툴체인에 맞춥니다. 환경 변경 시 diff를 검토한 후 명시적으로 갱신해야 합니다.
- runtime 산출물은 Git에 포함되지 않으므로 발표용 MP4는 별도로 복사해야 합니다.

재실행: 프로젝트 루트에서 `bash scripts/run-all-local.sh`.
발표 절차: [PRESENTATION_DEMO_RUNBOOK](PRESENTATION_DEMO_RUNBOOK.md).
