import XCTest
@testable import JitterJuice

@MainActor
final class SettingsClampingTests: XCTestCase {
    private var model: AppModel!

    override func setUp() {
        super.setUp()
        model = AppModel()
    }

    func testJiggleIntervalClampsLow() {
        model.jiggleIntervalSeconds = 10
        XCTAssertEqual(model.jiggleIntervalSeconds, 15)
    }

    func testJiggleIntervalClampsHigh() {
        model.jiggleIntervalSeconds = 500
        XCTAssertEqual(model.jiggleIntervalSeconds, 300)
    }

    func testApplyIntervalFromStepper() {
        model.applyIntervalFromStepper(10)
        XCTAssertEqual(model.jiggleIntervalSeconds, 15)
        model.applyIntervalFromStepper(400)
        XCTAssertEqual(model.jiggleIntervalSeconds, 300)
        model.applyIntervalFromStepper(45)
        XCTAssertEqual(model.jiggleIntervalSeconds, 45)
    }

    func testIdleThresholdClampsLow() {
        model.jiggleIdleThresholdSeconds = 1
        XCTAssertEqual(model.jiggleIdleThresholdSeconds, 5)
    }

    func testIdleThresholdClampsHigh() {
        model.jiggleIdleThresholdSeconds = 1000
        XCTAssertEqual(model.jiggleIdleThresholdSeconds, 600)
    }

    func testApplyIdleThresholdFromStepper() {
        model.applyIdleThresholdFromStepper(1)
        XCTAssertEqual(model.jiggleIdleThresholdSeconds, 5)
        model.applyIdleThresholdFromStepper(999)
        XCTAssertEqual(model.jiggleIdleThresholdSeconds, 600)
    }

    func testNudgePixelsClampsLow() {
        model.nudgePixels = 0
        XCTAssertEqual(model.nudgePixels, 1)
    }

    func testNudgePixelsClampsHigh() {
        model.nudgePixels = 100
        XCTAssertEqual(model.nudgePixels, 25)
    }

    func testApplyNudgePixelsFromStepper() {
        model.applyNudgePixelsFromStepper(0)
        XCTAssertEqual(model.nudgePixels, 1)
        model.applyNudgePixelsFromStepper(50)
        XCTAssertEqual(model.nudgePixels, 25)
    }

    func testStayAwakeAutoStopMinutesClampsHigh() {
        model.stayAwakeAutoStopMinutes = 2000
        XCTAssertEqual(model.stayAwakeAutoStopMinutes, 24 * 60)
    }

    func testStayAwakeAutoStopMinutesAllowsZero() {
        model.stayAwakeAutoStopMinutes = 0
        XCTAssertEqual(model.stayAwakeAutoStopMinutes, 0)
    }

    func testDailyStartMinuteClamps() {
        model.stayAwakeDailyStartMinute = -100
        XCTAssertEqual(model.stayAwakeDailyStartMinute, 0)
        model.stayAwakeDailyStartMinute = 5000
        XCTAssertEqual(model.stayAwakeDailyStartMinute, 1439)
    }

    func testDailyEndMinuteClamps() {
        model.stayAwakeDailyEndMinute = -1
        XCTAssertEqual(model.stayAwakeDailyEndMinute, 0)
        model.stayAwakeDailyEndMinute = 9999
        XCTAssertEqual(model.stayAwakeDailyEndMinute, 1439)
    }

    func testCustomMainHexSanitization() {
        model.applyCustomMainHexInput("zz#12ab34cd")
        XCTAssertEqual(model.customThemeMainHex, "12AB34")
    }

    func testCustomAccentHexSanitization() {
        model.applyCustomAccentHexInput("!!!")
        XCTAssertEqual(model.customThemeAccentHex, "")
        model.applyCustomAccentHexInput("ab#12cd")
        XCTAssertEqual(model.customThemeAccentHex, "AB12CD")
    }
}
