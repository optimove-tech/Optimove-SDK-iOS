//  Copyright © 2017 Optimove. All rights reserved.

public struct Parameter: Codable, Equatable {
    public let type: String
    public let optional: Bool

    public init(
        type: String,
        optional: Bool) {
        self.type = type
        self.optional = optional
    }

    public var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case type
        case optional
    }

}
