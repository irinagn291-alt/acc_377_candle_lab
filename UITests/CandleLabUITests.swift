import XCTest

final class CandleLabUITests: XCTestCase {
    @MainActor func snapshot(_ name:String) {
        Thread.sleep(forTimeInterval:0.5)
        let attachment=XCTAttachment(screenshot:XCUIScreen.main.screenshot());attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)
    }
    @MainActor func reveal(_ element:XCUIElement,in app:XCUIApplication) {
        for _ in 0..<6 { if element.isHittable { return };app.swipeUp() }
    }
    @MainActor func testFullLearningFlow() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        XCTAssertTrue(app.otherElements["candleChart"].waitForExistence(timeout:15))
        snapshot("01-practice-first-launch")
        app.buttons["Zoom in"].tap()
        XCTAssertTrue(app.staticTexts["1.5×"].exists)
        app.buttons["Fit chart"].tap()
        let answer=app.buttons["answer1"];reveal(answer,in:app);answer.tap()
        XCTAssertTrue(app.staticTexts["Let’s look again"].waitForExistence(timeout:3))
        snapshot("02-feedback")
        let review=app.buttons["review"];reveal(review,in:app);review.tap()
        XCTAssertTrue(app.staticTexts["See the reasoning."].waitForExistence(timeout:3))
        snapshot("03-breakdown")
        app.buttons["Done"].tap()
        app.tabBars.buttons["Overview"].tap();snapshot("04-overview")
        app.tabBars.buttons["Lessons"].tap()
        app.buttons["lesson-Candle anatomy"].tap()
        let read=app.buttons["markRead"];reveal(read,in:app);read.tap()
        XCTAssertTrue(app.buttons["Read ✓"].exists)
        snapshot("05-lesson")
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["0%"].firstMatch.exists)
        snapshot("06-progress")
        app.terminate();app.launchArguments=[];app.launch()
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["1/6"].exists)
    }
    @MainActor func testMarkupAndReplay() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        XCTAssertTrue(app.otherElements["candleChart"].waitForExistence(timeout:15))
        let markup=app.buttons["markup"];reveal(markup,in:app);markup.tap()
        XCTAssertTrue(app.buttons["markupDone"].waitForExistence(timeout:3))
        let level=app.buttons["accessibleLevel"];reveal(level,in:app);level.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","1 saved annotations")).firstMatch.exists)
        snapshot("07-markup-level")
        app.buttons["Undo"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","0 saved annotations")).firstMatch.exists)
        level.tap();app.buttons["markupDone"].tap()
        let restart=app.buttons["Restart replay"];reveal(restart,in:app);restart.tap()
        XCTAssertTrue(app.staticTexts["6 / 36"].exists)
        app.buttons["Step"].tap();XCTAssertTrue(app.staticTexts["7 / 36"].exists)
        app.buttons["Reveal all candles"].tap()
        XCTAssertTrue(app.staticTexts["36 / 36"].exists)
        app.buttons["markup"].tap();reveal(level,in:app)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","1 saved annotations")).firstMatch.exists)
        app.buttons["markupDone"].tap()
        reveal(restart,in:app);restart.tap()
        app.terminate();app.launchArguments=[];app.launch()
        XCTAssertTrue(app.steppers["cursorStepper"].waitForExistence(timeout:15))
        XCTAssertEqual(app.steppers["cursorStepper"].label,"Candle 6 / 6")
    }
    @MainActor func testLibraryEmptySearch() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        XCTAssertTrue(app.tabBars.buttons["Lessons"].waitForExistence(timeout:15))
        app.tabBars.buttons["Lessons"].tap()
        let search=app.textFields["lessonSearch"];search.tap();search.typeText("zzzz")
        XCTAssertTrue(app.staticTexts["No matching lessons"].waitForExistence(timeout:3))
        snapshot("08-empty-search")
    }

    @MainActor func testResponsiveLayoutAndDrawing() {
        let app=XCUIApplication();app.launchArguments=["--ui-testing"];app.launch()
        XCTAssertTrue(app.otherElements["candleChart"].waitForExistence(timeout:15))
        snapshot("09-responsive-practice")
        let markup=app.buttons["markup"];reveal(markup,in:app);markup.tap()
        XCTAssertTrue(app.buttons["markupDone"].waitForExistence(timeout:3))
        app.buttons["Trend line"].tap()
        let chart=app.otherElements["markupChart"]
        chart.coordinate(withNormalizedOffset:CGVector(dx:0.2,dy:0.6)).press(forDuration:0.1,thenDragTo:chart.coordinate(withNormalizedOffset:CGVector(dx:0.7,dy:0.3)))
        app.buttons["Zone"].tap()
        chart.coordinate(withNormalizedOffset:CGVector(dx:0.3,dy:0.25)).press(forDuration:0.1,thenDragTo:chart.coordinate(withNormalizedOffset:CGVector(dx:0.6,dy:0.5)))
        snapshot("10-drawing-tools")
        let level=app.buttons["accessibleLevel"];reveal(level,in:app)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","2 saved annotations")).firstMatch.exists)
        app.buttons["markupDone"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        snapshot("11-landscape")
        XCUIDevice.shared.orientation = .portrait
        app.terminate()
        app.launchArguments=["--ui-testing","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryXXXL"]
        app.launch();XCTAssertTrue(app.otherElements["candleChart"].waitForExistence(timeout:15))
        snapshot("12-large-type")
    }
}
