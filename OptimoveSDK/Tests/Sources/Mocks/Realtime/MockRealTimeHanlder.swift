//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class RealTimeHanlderAssertionProxy: RealTimeHanlder {

    private let target: RealTimeHanlder

    init(target: RealTimeHanlder) {
        self.target = target
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

}
