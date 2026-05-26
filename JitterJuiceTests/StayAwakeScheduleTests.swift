import XCTest
@testable import JitterJuice

final class StayAwakeScheduleTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 5, day: 26, hour: hour, minute: minute))!
    }

    func testSameDayWindowInside() {
        XCTAssertTrue(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 12, minute: 0),
                startMinute: 360,
                endMinute: 1020,
                calendar: calendar
            )
        )
    }

    func testSameDayWindowOutside() {
        XCTAssertFalse(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 5, minute: 0),
                startMinute: 360,
                endMinute: 1020,
                calendar: calendar
            )
        )
    }

    func testSameDayWindowAtEndIsOutside() {
        XCTAssertFalse(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 17, minute: 0),
                startMinute: 360,
                endMinute: 1020,
                calendar: calendar
            )
        )
    }

    func testOvernightWindowEvening() {
        XCTAssertTrue(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 23, minute: 0),
                startMinute: 1320,
                endMinute: 360,
                calendar: calendar
            )
        )
    }

    func testOvernightWindowMorningGap() {
        XCTAssertFalse(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 12, minute: 0),
                startMinute: 1320,
                endMinute: 360,
                calendar: calendar
            )
        )
    }

    func testOvernightWindowEarlyMorning() {
        XCTAssertTrue(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 3, minute: 0),
                startMinute: 1320,
                endMinute: 360,
                calendar: calendar
            )
        )
    }

    func testStartEqualsEndAlwaysActive() {
        XCTAssertTrue(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 12, minute: 0),
                startMinute: 600,
                endMinute: 600,
                calendar: calendar
            )
        )
    }

    func testClampsOutOfRangeMinutes() {
        XCTAssertTrue(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 0, minute: 0),
                startMinute: -10,
                endMinute: 60,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            StayAwakeSchedule.isWithinActiveWindow(
                now: date(hour: 23, minute: 59),
                startMinute: 0,
                endMinute: 2000,
                calendar: calendar
            )
        )
    }

    func testClampDayMinuteBoundaries() {
        XCTAssertEqual(StayAwakeSchedule.clampDayMinute(-10), 0)
        XCTAssertEqual(StayAwakeSchedule.clampDayMinute(0), 0)
        XCTAssertEqual(StayAwakeSchedule.clampDayMinute(1439), 1439)
        XCTAssertEqual(StayAwakeSchedule.clampDayMinute(2000), 1439)
    }
}
