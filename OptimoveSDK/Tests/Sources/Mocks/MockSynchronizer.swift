//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class MockSynchronizer: Synchronizer {

    var assertFunction: ((CommonOperation) -> Void)?

    func handle(_ op: CommonOperation) {
        assertFunction?(op)
    }

    func addNode(_: Node) {

    }

    func onResignActive() {

    }

}
