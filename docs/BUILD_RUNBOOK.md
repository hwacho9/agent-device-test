# Build and run

Run from the repository root with Bash. Scripts select installed JDK 17, not the
shell's default JDK. Set DEMO_JAVA_HOME or DEMO_ANDROID_SDK to override explicitly.
Dependencies are pinned in gradle/libs.versions.toml and the Gradle wrapper.

```sh
bash scripts/check-environment.sh
source scripts/env.sh
./gradlew :shared:testAndroidHostTest
./gradlew :androidApp:compileDebugKotlin :shared:linkDebugFrameworkIosSimulatorArm64
bash scripts/build-android.sh
bash scripts/install-android.sh
python3 scripts/android-smoke.py
bash scripts/build-ios.sh
bash scripts/install-ios.sh
```

Common tests live in shared/src/commonTest. testAndroidHostTest is the actual
registered Android host task, verified by Gradle tasks --all.

Android: com.example.agentdevicee2edemo; dedicated AVD AgentDeviceE2EDemo_API35,
serial emulator-5580, API 35 ARM64. Only this app's data is reset.

Xcode project: iosApp/AgentDeviceE2EDemo.xcodeproj; scheme AgentDeviceE2EDemo;
bundle com.example.agentdevicee2edemo.ios; framework Shared. Default destination
is iPhone 17 Pro, iOS 26.5, UDID 2D1249E5-37FA-4800-A45E-9A7D1ABD651F.

The Xcode Run Script executes embedAndSignAppleFrameworkForXcode before Swift
compilation. build-ios.sh checks both the final app executable and embedded
Shared.framework. It never treats framework-only compilation as an app build.

Build outputs are copied or generated under artifacts/{android,ios}/build.
An APK is sized with stat; an app bundle is sized by summing its actual files.

## Reset
reset-android-demo.sh clears only the demo package on the dedicated AVD.
reset-ios-demo.sh reinstalls only the demo package on the selected Simulator.
Both discard the in-memory session and return to Login.
