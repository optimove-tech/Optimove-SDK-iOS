//  Copyright © 2020 Optimove. All rights reserved.

enum JsonType: Encodable {
    case number(Int)
    case string(String)
    case bool(Bool)
    case array([JsonType])
    case dictionary([String: JsonType])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let number):
            try container.encode(number)
        case .string(let string):
            try container.encode(string)
        case .bool(let bool):
            try container.encode(bool)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dictionary):
            try container.encode(dictionary)
        }
    }

}

typealias OptistreamEventContext = [String: JsonType]

struct OptistreamEvent: Encodable {
    let tenant: UInt8
    let category: String
    let event: String
    let origin: String
    let customer: String?
    let visitor: String
    let timestamp: UInt32
    let context: OptistreamEventContext
}
