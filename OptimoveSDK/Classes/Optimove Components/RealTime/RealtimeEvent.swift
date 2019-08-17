//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class RealtimeEvent: Encodable {
    var tid: String
    var cid: String?
    var visitorId: String?
    var eid: String
    var firstVisitorDate: String
    var context: [String: Any]

    enum CodingKeys: String, CodingKey {
        case tid
        case cid
        case visitorId
        case eid
        case context
        case firstVisitorDate
    }

    init(tid: String,
         cid: String?,
         visitorId: String?,
         eid: String,
         context: [String: Any],
         firstVisitorDate: Int) {
        self.tid = tid
        self.visitorId = (cid != nil) ? nil : visitorId
        self.cid = cid
        self.eid = eid
        self.context = context
        self.firstVisitorDate = String(firstVisitorDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tid, forKey: .tid)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(visitorId, forKey: .visitorId)
        try container.encode(eid, forKey: .eid)
        try container.encode(firstVisitorDate, forKey: .firstVisitorDate)

        var contextContainer = container.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .context)
        for (key, value) in context {
            guard let key = RuntimeCodingKey(stringValue: key) else {
                continue
            }
            switch value {
                case let value as String:
                    try contextContainer.encode(value, forKey: key)
                case let value as Int:
                    try contextContainer.encode(value, forKey: key)
                case let value as Double:
                    try contextContainer.encode(value, forKey: key)
                case let value as Float:
                    try contextContainer.encode(value, forKey: key)
                case let value as Bool:
                    try contextContainer.encode(value, forKey: key)
                default:
                    print("Type \(type(of: value)) not supported")
            }
        }
    }
}
