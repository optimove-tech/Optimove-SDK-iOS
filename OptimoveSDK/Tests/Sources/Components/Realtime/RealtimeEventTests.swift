//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class RealtimeEventTests: XCTestCase {

    func test_encoding_event_with_cid_and_visitorID() {
        let event = RealtimeEvent(
            tid: "tid",
            cid: "cid",
            visitorId: "visitorId",
            eid: "eid",
            context: [
                "string": "value",
                "int": 1,
                "double": Double.pi,
                "float": Float.pi,
                "bool": true,
                "unsuported": EmptyClass()
            ],
            firstVisitorDate: 100
        )
        XCTAssertNoThrow(try JSONEncoder().encode(event))
    }

    func test_without_cid() {
        // given
        let event = RealtimeEvent(
            tid: "tid",
            cid: nil,
            visitorId: "visitorId",
            eid: "eid",
            context: [
                "string": "value",
                "int": 1,
                "double": Double.pi,
                "float": Float.pi,
                "bool": true,
                "unsuported": EmptyClass()
            ],
            firstVisitorDate: 100
        )

        // then
        XCTAssertNoThrow(try JSONEncoder().encode(event))
    }

    func test_without_visitorID() {
        // given
        let event = RealtimeEvent(
            tid: "tid",
            cid: "cid",
            visitorId: nil,
            eid: "eid",
            context: [
                "string": "value",
                "int": 1,
                "double": Double.pi,
                "float": Float.pi,
                "bool": true,
                "unsuported": EmptyClass()
            ],
            firstVisitorDate: 100
        )

        // then
        XCTAssertNoThrow(try JSONEncoder().encode(event))
    }

}

private final class EmptyClass {

    init() { }

}
