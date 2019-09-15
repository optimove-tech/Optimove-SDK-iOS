//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class VisitorIDPreprocessorTests: XCTestCase {

    func testExample() {
        let userID = "8D2850F9-ECB0-4693-98EF-F3286E8B685E"
        let visitorID = "cbfccafd4c52ab8a"

        let result = VisitorIDPreprocessor.process(userID)

        XCTAssertEqual(result, visitorID)
    }

}
