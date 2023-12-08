//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveSDK

public final class OptistreamNetworkingMock: OptistreamNetworking {
    public init() {}

    public var assetEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<Void, NetworkError>) -> Void) -> Void)?

    public func send(events: [OptistreamEvent], completion: @escaping (Result<Void, NetworkError>) -> Void) {
        assetEventsFunction?(events, completion)
    }

    public func send(events: [OptistreamEvent], path _: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        assetEventsFunction?(events, completion)
    }
}
