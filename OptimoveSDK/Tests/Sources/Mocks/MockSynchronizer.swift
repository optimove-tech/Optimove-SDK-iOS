//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class MockSynchronizer: Synchronizer {

    var assertFunction: ((Operation) -> Void)?

    func handle(_ op: Operation) {
        assertFunction?(op)
    }

    func addNode(_: Node) {

    }

    func onResignActive() {

    }

}
