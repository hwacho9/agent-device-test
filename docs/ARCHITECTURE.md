# Architecture

`shared/commonMain` owns demo credentials, session, profile and save state.
`androidApp` uses Jetpack Compose. `iosApp` uses SwiftUI. Both call `DemoSession`.
There is no backend, persistence, clock, randomness or shared Compose UI.

## State lifecycle
A new process creates a logged-out session with Demo User and reminders off.
Login errors are persistent until the next submit. Successful login goes Home.
Profile saves update the common state and keep Saved visible until reset.
UI adapters publish copies of common state; they do not duplicate validation.

## iOS
Shared is an Objective-C-compatible Kotlin framework consumed with `import Shared`.
The app's Xcode Run Script runs `:shared:embedAndSignAppleFrameworkForXcode`
before Swift compilation. CocoaPods is not used. SnapshotTesting is a separate
Swift Package Manager dependency of the XCTest target.

## Test layers
Common tests validate business rules. Android previews and iOS hosting-controller
snapshots validate 11 deterministic states per platform. Real installed apps are
then explored through agent-device and replayed twice from a fresh state.
Reference recording is explicit and never part of validation.
