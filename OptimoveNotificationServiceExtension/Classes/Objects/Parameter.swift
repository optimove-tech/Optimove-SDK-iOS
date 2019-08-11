import Foundation

struct Parameter: Decodable {
    let mandatory: Bool
    let name: String
    let id: Int
    let type: String
    let optiTrackDimensionId: Int

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case type
        case optiTrackDimensionId
        case optional
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let optional = try values.decode(Bool.self, forKey: .optional)
        mandatory = !optional
        name = try values.decode(String.self, forKey: .name)
        id = try values.decode(Int.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        optiTrackDimensionId = try values.decode(Int.self, forKey: .optiTrackDimensionId)
    }
}
