//  Copyright © 2017 Optimove. All rights reserved.

public struct Parameter: Codable {
    public let type: String
    public let optiTrackDimensionId: Int
    public let optional: Bool

    public var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case type
        case optiTrackDimensionId
        case optional
    }

}
