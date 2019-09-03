//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Component { }

protocol EventableComponent: Component {
    func handleEventable(_ operation: EventableOperation) throws
}

protocol PushableComponent: Component {
    func handlePushable(_ operation: PushableOperation) throws
}
