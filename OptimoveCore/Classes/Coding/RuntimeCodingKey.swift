//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public protocol OptimoveEvent {
    @objc var name: String { get }
    @objc var parameters: [String: Any] { get }
}

final class RuntimeCodingKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }

}
