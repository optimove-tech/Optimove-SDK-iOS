//  Copyright © 2017 Optimove.

import Foundation

struct Parameter: Codable {
    let name: String
    let id: Int
    let type: String
    let optiTrackDimensionId: Int
    let optional: Bool

    var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case type
        case optiTrackDimensionId
        case optional
    }

}
