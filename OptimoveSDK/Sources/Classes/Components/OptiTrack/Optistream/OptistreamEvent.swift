//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

struct OptistreamEvent {
    let uuid: String
    let tenant: Int
    let category: String
    let event: String
    let origin: String
    let customer: String?
    let visitor: String
    let timestamp: TimeInterval
    let context: [String: Any]
}

extension OptistreamEvent: Equatable {

    static func == (lhs: OptistreamEvent, rhs: OptistreamEvent) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}

extension OptistreamEvent: JSONSerializable  {

    var dictionary: [String: Any] {
        return [
            (\OptistreamEvent.uuid).stringValue: self.uuid,
            (\OptistreamEvent.tenant).stringValue: self.tenant,
            (\OptistreamEvent.category).stringValue: self.category,
            (\OptistreamEvent.event).stringValue: self.event,
            (\OptistreamEvent.origin).stringValue: self.origin,
            (\OptistreamEvent.visitor).stringValue: self.visitor,
            (\OptistreamEvent.timestamp).stringValue: self.timestamp,
            (\OptistreamEvent.context).stringValue: self.context,
        ]
    }
}

extension PartialKeyPath where Root == OptistreamEvent {
    var stringValue: String {
        switch self {
        case \OptistreamEvent.uuid: return "uuid"
        case \OptistreamEvent.tenant: return "tenant"
        case \OptistreamEvent.category: return "category"
        case \OptistreamEvent.event: return "event"
        case \OptistreamEvent.origin: return "origin"
        case \OptistreamEvent.visitor: return "visitor"
        case \OptistreamEvent.timestamp: return "timestamp"
        case \OptistreamEvent.context: return "context"
        default: fatalError("Event contains unexpected key path")
        }
    }
}

protocol JSONSerializable {
    var dictionary: [String: Any] { get }
}

extension JSONSerializable {
    /// Converts a JSONSerializable conforming class to a JSON object.
    func json() throws -> Data {
        try JSONSerialization.data(withJSONObject: self.dictionary, options: [])
    }
}
