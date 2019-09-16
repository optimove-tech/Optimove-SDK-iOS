//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class Chain {

    private(set) var next: Node

    init(next: Node) {
        self.next = next
    }

}

extension Chain: ResignActiveSubscriber {

    func onResignActive() {
        do {
            try next.execute(.init(.eventable(.dispatchNow)))
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
