//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class MockSynchronizer: Synchronizer {

    var assertFunctionEventable: ((EventableOperation) -> Void)?
    var assertFunctionPushable: ((PushableOperation) -> Void)?

    func handle(_ op: EventableOperation) {
        assertFunctionEventable?(op)
    }

    func handle(_ op: PushableOperation) {
        assertFunctionPushable?(op)
    }

}
