import XCTest

final class SmokeTests: XCTestCase {
    func testLoginProfileSave() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-demo-test-mode"]
        app.launch()
        let email = app.textFields["login.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 15))
        email.tap()
        email.typeText("demo@example.com")
        let password = app.secureTextFields["login.password"]
        password.tap()
        password.typeText("demo1234")
        app.buttons["login.submit"].tap()
        XCTAssertTrue(app.staticTexts["home.title"].waitForExistence(timeout: 10))
        app.buttons["home.profile"].tap()
        XCTAssertTrue(app.staticTexts["profile.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["profile.name"].exists)
        let reminder = app.switches["profile.reminder"]
        XCTAssertEqual(reminder.value as? String, "0")
        reminder.tap()
        XCTAssertEqual(reminder.value as? String, "1")
        app.buttons["profile.save"].tap()
        XCTAssertTrue(app.staticTexts["profile.saved"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["login.error"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "gate-d-saved"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
