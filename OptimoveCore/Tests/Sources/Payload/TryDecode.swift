//  Copyright © 2019 Optimove. All rights reserved.

import XCTest

let tryDecode: (() throws -> Void) -> Void = { function in
    do {
        try function()
    } catch let DecodingError.dataCorrupted(context) {
        XCTFail(context.debugDescription)
    } catch let DecodingError.keyNotFound(key, context) {
        XCTFail("Key '\(key)' not found: \(context.debugDescription)\ncodingPath: \(context.codingPath)")
    } catch let DecodingError.valueNotFound(value, context) {
        XCTFail("Value '\(value)' not found: \(context.debugDescription)\ncodingPath: \(context.codingPath)")
    } catch let DecodingError.typeMismatch(type, context)  {
        XCTFail("Type '\(type)' mismatch: \(context.debugDescription)\ncodingPath: \(context.codingPath)")
    } catch {
        XCTFail(error.localizedDescription)
    }
}
