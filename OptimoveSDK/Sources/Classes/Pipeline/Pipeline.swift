//  Copyright © 2019 Optimove. All rights reserved.

import Dispatch
import OptimoveCore

/// Use for executing a internal operation flow with serial queue.
protocol Pipeline: ResignActiveSubscriber {
    func deliver(_: CommonOperation)
}

protocol PipelineMutator: Pipeline {
    func addNextPipe(_: Pipe)
}

final class PipelineImpl {

    private let queue: DispatchQueue
    private let pipe: Pipe

    init(pipe: Pipe) {
        queue = DispatchQueue(label: "com.optimove.pipeline", qos: .userInitiated)
        self.pipe = pipe
    }

}

extension PipelineImpl: Pipeline {

    func deliver(_ operation: CommonOperation) {
        queue.async { [pipe] in
            tryCatch {
                try pipe.next?.deliver(operation)
            }
        }
    }

}

extension PipelineImpl: PipelineMutator {

    func addNextPipe(_ nextPipe: Pipe) {
        queue.async { [pipe] in
            // The first pipe should be a InMemortyBuffer.
            pipe.next = nextPipe
        }
    }

}

extension PipelineImpl: ResignActiveSubscriber {

    func onResignActive() {
        deliver(.dispatchNow)
    }

}
