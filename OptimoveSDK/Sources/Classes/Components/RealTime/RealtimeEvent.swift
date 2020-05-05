//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RealtimeEvent: Encodable {
    var tid: String
    var cid: String?
    var visitorId: String?
    var eid: String
    var firstVisitorDate: String
    var context: JSON

    init(tid: String,
         cid: String?,
         visitorId: String?,
         eid: String,
         context: [String: Any],
         firstVisitorDate: Int) throws {
        self.tid = tid
        self.visitorId = (cid != nil) ? nil : visitorId
        self.cid = cid
        self.eid = eid
        self.context = try JSON(context)
        self.firstVisitorDate = String(firstVisitorDate)
    }

}
