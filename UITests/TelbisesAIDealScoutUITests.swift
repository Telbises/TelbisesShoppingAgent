import XCTest

final class TelbisesAIDealScoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        ensureSignedInByGoogleIfNeeded()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testHomeShowsVoiceAndImageSearchButtons() {
        XCTAssertTrue(app.buttons["Search using image"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start voice search"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Shopping intent"].waitForExistence(timeout: 5))
    }

    func testCanTypeAndSendPrompt() {
        let input = app.textFields["Shopping intent"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("work laptop under 1000")

        let sendButton = app.buttons["Send message"]
        XCTAssertTrue(sendButton.exists)
        sendButton.tap()

        XCTAssertTrue(waitForResultOrErrorState(timeout: 10))
    }

    private func waitForResultOrErrorState(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons["View results"].exists {
                return true
            }

            let errorShown = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "couldn't fetch deals")).count > 0
            let liveErrorShown = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Live web results are unavailable")).count > 0
            if errorShown || liveErrorShown {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return false
    }

    private func ensureSignedInByGoogleIfNeeded() {
        let googleButton = app.buttons["Continue with Google"]
        if googleButton.waitForExistence(timeout: 2) {
            googleButton.tap()
        }
    }
}
