//  Copyright © 2020 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class OptistreamEventTests: XCTestCase {

    func testExample() throws {
        let event = OptistreamEvent(
            tenant: 1,
            category: "category",
            event: "event",
            origin: "origin",
            customer: "customer",
            visitor: "visitor",
            timestamp: 1587283669,
            context: [
                "number_key": .number(2),
                "string_key": .string("string_value"),
                "bool_key": .bool(true),
                "array_key": .array(
                    [
                        .number(3),
                        .string("3"),
                    ]
                ),
                "dictionary_key": .dictionary(
                    [
                        "1": .number(4),
                        "2": .string("4")
                    ]
                )
            ]
        )

        let _ = try JSONEncoder().encode(event)
    }
}
