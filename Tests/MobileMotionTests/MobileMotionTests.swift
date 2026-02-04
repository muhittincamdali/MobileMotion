import XCTest
@testable import MobileMotion

final class MobileMotionTests: XCTestCase {
    func testSharedInstance() {
        XCTAssertNotNil(MobileMotion.shared)
    }
}
