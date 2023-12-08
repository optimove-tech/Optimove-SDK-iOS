//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class RuntimeCodingKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        stringValue = String(intValue)
    }
}
