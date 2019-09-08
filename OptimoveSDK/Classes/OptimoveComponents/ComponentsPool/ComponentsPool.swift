//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol ComponentsPool: EventableComponent, PushableComponent { }

protocol MutableComponentsPool: ComponentsPool {
    func addComponent(_: Component)
}

final class ComponentsPoolImpl {
    private var eventableComponents: [EventableComponent] = []
    private var pushableComponents: [PushableComponent] = []
}

extension ComponentsPoolImpl: ComponentsPool { }

extension ComponentsPoolImpl: EventableComponent {

    func handleEventable(_ context: EventableOperationContext) throws {
        eventableComponents.forEach { component in
            do {
                try component.handleEventable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}

extension ComponentsPoolImpl: PushableComponent {

    func handlePushable(_ context: PushableOperationContext) throws {
        pushableComponents.forEach { component in
            do {
                try component.handlePushable(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}

extension ComponentsPoolImpl: MutableComponentsPool {

    func addComponent(_ component: Component) {
        switch component {
        case let component as EventableComponent:
            eventableComponents.append(component)
        case let component as PushableComponent:
            pushableComponents.append(component)
        default:
            fatalError("Unable to add a compnent. Reason: Unsupported component.")
        }
    }
}
