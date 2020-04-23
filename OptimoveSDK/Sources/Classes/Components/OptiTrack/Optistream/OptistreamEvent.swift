//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct OptistreamEvent: Codable {
    let uuid: String
    let tenant: Int
    let category: String
    let event: String
    let origin: String
    let customer: String?
    let visitor: String
    let timestamp: TimeInterval
    let context: JSON
}

extension OptistreamEvent: Equatable {

    static func == (lhs: OptistreamEvent, rhs: OptistreamEvent) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}
