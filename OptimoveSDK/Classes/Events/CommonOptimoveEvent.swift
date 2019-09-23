//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

class CommonOptimoveEvent: OptimoveEvent {
    var name: String
    var parameters: [String: Any]

    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }

}
