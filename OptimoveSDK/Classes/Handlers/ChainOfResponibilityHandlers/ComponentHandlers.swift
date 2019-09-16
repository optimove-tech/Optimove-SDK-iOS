//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class ComponentEventableHandler: EventableNode {
    private let components: [EventableComponent]

    init(components: [EventableComponent]) {
        self.components = components
    }

    // MARK: - EventableHandler

    override func execute(_ context: EventableOperationContext) throws {
        components.forEach { component in
            do {
                try component.handleEventable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}

class ComponentPushableHandler: PushableNode {
    private let components: [PushableComponent]

    init(components: [PushableComponent]) {
        self.components = components
    }

    // MARK: - PushableHandler

    override func execute(_ context: PushableOperationContext) throws {
        components.forEach { component in
            do {
                try component.handlePushable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
