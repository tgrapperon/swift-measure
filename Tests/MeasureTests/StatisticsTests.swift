@testable import Measure
import XCTest

final class StatisticsTests: XCTestCase {
  func testMeanAndStandardDeviation() throws {
    let array: [Double] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let measure = array.extractMeasure()
    XCTAssertEqual(measure?.value, 5.5)
    XCTAssertEqual(measure?.std ?? 0, 2.872281323269, accuracy: 1e-12)
    XCTAssertEqual(measure?.error ?? 0, 0.90829510622925, accuracy: 1e-12)
  }
}
