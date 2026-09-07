import XCTest
import SwiftUI
import SnapshotTesting
@testable import AgentDeviceE2EDemo

@MainActor
final class ScreenSnapshotTests: XCTestCase {
    private func check<V: View>(_ view: V, name: String, dark: Bool = false, large: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let recording = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        let refs = URL(fileURLWithPath: String(describing: #filePath)).deletingLastPathComponent().appendingPathComponent("__Snapshots__").path
        let content = view
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, large ? .accessibility1 : .large)
            .tint(Color(red: 0, green: 0.42, blue: 0.37))
            .transaction { $0.disablesAnimations = true }
        let controller = UIHostingController(rootView: content)
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: dark ? .dark : .light),
            UITraitCollection(preferredContentSizeCategory: large ? .accessibilityMedium : .large)
        ])
        let failure = verifySnapshot(of: controller, as: .image(on: .iPhone13, drawHierarchyInKeyWindow: true, traits: traits), named: name, record: recording ? .all : .never, snapshotDirectory: refs, file: file, testName: name, line: line)
        if recording {
            XCTAssertTrue(failure?.hasPrefix("Record mode is on. Automatically recorded snapshot:") == true, failure ?? "Expected a recorded reference", file: file, line: line)
        } else if let failure {
            XCTFail(failure, file: file, line: line)
        }
    }
    func testLoginDefault() { check(LoginScreen(email: .constant(""), password: .constant("")), name: "LoginDefault") }
    func testLoginError() { check(LoginScreen(email: .constant(""), password: .constant(""), error: "Invalid email or password"), name: "LoginError") }
    func testLoginDark() { check(LoginScreen(email: .constant(""), password: .constant("")), name: "LoginDark", dark: true) }
    func testLoginLargeFont() { check(LoginScreen(email: .constant(""), password: .constant("")), name: "LoginLargeFont", large: true) }
    func testHomeDefault() { check(HomeScreen(), name: "HomeDefault") }
    func testHomeDark() { check(HomeScreen(), name: "HomeDark", dark: true) }
    func testProfileDefault() { check(ProfileScreen(reminders: .constant(false)), name: "ProfileDefault") }
    func testProfileReminderEnabled() { check(ProfileScreen(reminders: .constant(true)), name: "ProfileReminderEnabled") }
    func testProfileSaved() { check(ProfileScreen(reminders: .constant(true), saved: true), name: "ProfileSaved") }
    func testProfileDark() { check(ProfileScreen(reminders: .constant(false)), name: "ProfileDark", dark: true) }
    func testProfileLargeFont() { check(ProfileScreen(reminders: .constant(false)), name: "ProfileLargeFont", large: true) }
}
