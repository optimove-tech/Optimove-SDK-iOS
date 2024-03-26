//  Copyright © 2017 Optimove. All rights reserved.

struct Parameter: Codable, Equatable {
    let type: String
    let optional: Bool

    init(
        type: String,
        optional: Bool
    ) {
        self.type = type
        self.optional = optional
    }

    var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case type
        case optional
    }
}
