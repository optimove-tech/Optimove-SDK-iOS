//  Copyright © 2017 Optimove. All rights reserved.

struct Parameter: Codable {
    let type: String
    let optiTrackDimensionId: Int
    let optional: Bool

    var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case type
        case optiTrackDimensionId
        case optional
    }

}
