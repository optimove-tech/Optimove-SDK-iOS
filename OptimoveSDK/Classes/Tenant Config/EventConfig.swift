//  Copyright © 2017 Optimove.

import Foundation

struct EventsConfig: Codable {
    let id: Int
    let supportedOnOptitrack: Bool
    let supportedOnRealTime: Bool
    let parameters: [String: Parameter]
}
