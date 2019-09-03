//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

class ComponentEventableHandler: EventableHandler {
    private let component: EventableComponent

    init(component: EventableComponent) {
        self.component = component
    }

    // MARK: - EventableHandler

    override func handle(_ operation: EventableOperation) throws {
        try component.handleEventable(operation)
    }

}

class ComponentPushableHandler: PushableHandler {
    private let component: PushableComponent

    init(component: PushableComponent) {
        self.component = component
    }

    // MARK: - EventableHandler

    override func handle(_ operation: PushableOperation) throws {
        try component.handlePushable(operation)
    }

}
