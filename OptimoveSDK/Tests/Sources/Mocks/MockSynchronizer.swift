//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class MockSynchronizer: Pipeline, PipelineMutator {

    var assertFunction: ((CommonOperation) -> Void)?

    func deliver(_ op: CommonOperation) {
        assertFunction?(op)
    }

    func addNextPipe(_: Pipe) {
        
    }

    func onResignActive() {

    }

}
