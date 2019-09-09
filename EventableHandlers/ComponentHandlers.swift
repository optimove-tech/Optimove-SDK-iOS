//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class ComponentEventableHandler: EventableHandler {
    private let components: [EventableComponent]

    init(components: [EventableComponent]) {
        self.components = components
    }

    // MARK: - EventableHandler

    override func handle(_ context: EventableOperationContext) throws {
        components.forEach { component in
            do {
                try component.handleEventable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}

class ComponentPushableHandler: PushableHandler {
    private let components: [PushableComponent]

    init(components: [PushableComponent]) {
        self.components = components
    }

    // MARK: - EventableHandler

    override func handle(_ context: PushableOperationContext) throws {
        components.forEach { component in
            do {
                try component.handlePushable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
