import XCTest
@testable import SwiftSIP

final class SwiftSIPTests: XCTestCase {
    func testCreateSwiiftSIP() throws {
        let sip = SwiftSIP()
        XCTAssertNotNil(sip)
    }
}
