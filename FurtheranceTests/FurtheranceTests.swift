//
//  FurtheranceTests.swift
//  FurtheranceTests
//
//  Created by Ricky Kresslein on 24.06.2024.
//

import XCTest
@testable import Furtherance

final class FurtheranceTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testSeparateTags() throws {
        let separated = separateTags(rawString: "#CAse #with multiple # #tags")
        XCTAssertEqual(separated, "#case #with multiple #tags")
    }
    
    func testNoSeconds() throws {
        let mins = formatTimeLongWithoutSeconds(165)
        XCTAssertEqual(mins, "0:02")
    }
    
    func testHoursWithoutPadding() throws {
        let seconds = formatTimeLongWithoutSeconds(3800)
        XCTAssertEqual(seconds, "1:03")
    }
    
    func testDoubleDigitHours() throws {
        let seconds = formatTimeLongWithoutSeconds(36060)
        XCTAssertEqual(seconds, "10:01")
    }
    
    func testLongTimeString() throws {
        let seconds = formatTimeLong(36082)
        XCTAssertEqual(seconds, "10:01:22")
    }
    
    func testNoHoursTimeString() throws {
        let seconds = formatTimeShort(800)
        XCTAssertEqual(seconds, "13:20")
    }
    
    func testShortTimeString() throws {
        let seconds = formatTimeShort(6082)
        XCTAssertEqual(seconds, "1:41:22")
    }
    
    func testDateYMDFormatted() throws {
        let date = Calendar.current.date(from: .init(year: 2024, month: 3, day: 21))
        let formattedDate = localDateFormatter.string(from: date!)
        XCTAssertEqual(formattedDate, "2024-03-21")
    }
    
    func testDateYMDHMSFormatted() throws {
        let date = Calendar.current.date(from: .init(year: 2024, month: 3, day: 21, hour: 6))
        let formattedDate = localDateTimeFormatter.string(from: date!)
        XCTAssertEqual(formattedDate, "2024-03-21 06:00:00")
    }
}
