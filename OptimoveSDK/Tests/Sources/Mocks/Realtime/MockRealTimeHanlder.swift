// Copiright 2019 Optimove

import Foundation
@testable import OptimoveSDK

final class RealTimeHanlderAssertionProxy: RealTimeHanlder {

    private let target: RealTimeHanlder

    init(target: RealTimeHanlder) {
        self.target = target
    }

    var handleOfflineAssertFunc: ((RealTimeEventType) -> Void)?

    func handleOffline(_ context: RealTimeEventContext) {
        handleOfflineAssertFunc?(context.type)
        target.handleOffline(context)
    }

    var handleOnSuccessAssertFunc: ((RealTimeEventType) -> Void)?

    func handleOnSuccess(_ context: RealTimeEventContext, json: String) {
        handleOnSuccessAssertFunc?(context.type)
        target.handleOnSuccess(context, json: json)
    }

    var handleOnErrorAssertFunc: ((RealTimeEventType, Error) -> Void)?

    func handleOnError(_ context: RealTimeEventContext, error: Error) {
        handleOnErrorAssertFunc?(context.type, error)
        target.handleOnError(context, error: error)
    }

    var handleOnCatchAssertFunc: ((RealTimeEventType, Error) -> Void)?

    func handleOnCatch(_ context: RealTimeEventContext, error: Error) {
        handleOnCatchAssertFunc?(context.type, error)
        target.handleOnCatch(context, error: error)
    }

}
