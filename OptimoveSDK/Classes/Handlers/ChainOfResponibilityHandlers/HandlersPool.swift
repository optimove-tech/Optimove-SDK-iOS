//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ChainPool {

    private(set) var eventableNode: Node<EventableOperationContext>
    private(set) var pushableNode: Node<PushableOperationContext>

    init(eventableNode: Node<EventableOperationContext>,
         pushableNode: Node<PushableOperationContext>) {
        self.eventableNode = eventableNode
        self.pushableNode = pushableNode
    }

}

extension ChainPool: ResignActiveSubscriber {

    func onResignActive() {
        do {
            try eventableNode.execute(.init(.dispatchNow))
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
