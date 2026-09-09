//  Copyright © 2026 Optimove. All rights reserved.

import OptimoveCore

public final class OptistreamDispatcherMock: OptistreamDispatcher {
    public init() {}

    /// Called with the events batch. Use the completion to report success/failure.
    /// The mock treats the entire batch as a single group (no customer splitting).
    public var assetEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<Void, NetworkError>) -> Void) -> Void)?

    public func sendBatch(
        events: [OptistreamEvent],
        path _: String?,
        onGroupResult: @escaping ([OptistreamEvent], Result<Void, NetworkError>) -> Void,
        completion: @escaping () -> Void
    ) {
        if let handler = assetEventsFunction {
            handler(events) { result in
                onGroupResult(events, result)
                completion()
            }
        } else {
            onGroupResult(events, .success(()))
            completion()
        }
    }
}
