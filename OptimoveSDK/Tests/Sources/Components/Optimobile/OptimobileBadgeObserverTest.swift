//
//  OptimobileBadgeObserverTest.swift
//  OptimoveSDK-Unit
//
//  Created by Barak Ben Hur on 16/05/2022.
//

import XCTest

class OptimobileBadgeObserverTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testObserveValue() throws {
        let observer = OptimobileBadgeObserver(callback: { badge in
            let expected = true
            let result = badge != -1
            XCTAssertEqual(result, expected, "testPushRequestDeviceToken fail")
        })
    }
}
