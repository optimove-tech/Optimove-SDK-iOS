//  Copyright © 2017 Optimove. All rights reserved.

public struct Parameter: Codable, Equatable {
    public let type: String
    public let optiTrackDimensionId: Int /// TODO: Remove it
    public let optional: Bool

    public init(
        type: String,
        optiTrackDimensionId: Int,
        optional: Bool) {
        self.type = type
        self.optiTrackDimensionId = optiTrackDimensionId
        self.optional = optional
    }

    public var mandatory: Bool {
        return !optional
    }

    enum CodingKeys: String, CodingKey {
        case type
        case optiTrackDimensionId
        case optional
    }

}
