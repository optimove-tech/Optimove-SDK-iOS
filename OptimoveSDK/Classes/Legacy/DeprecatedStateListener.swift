//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct OptimoveSuccessStateListenerWrapper {
    weak var observer: OptimoveSuccessStateListener?
}

// TODO: Delete the protocol declaration after SDK version 2.3.0
@available(*, deprecated, message: "This method will be deleted in the next version. Instead of subscribing as an listener use Optimove SDK directly.")
public protocol OptimoveSuccessStateListener: class {
    func optimove(
        _ optimove: Optimove,
        didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]
    )
}

final class OptimoveSuccessStateDelegateWrapper {
    var observer: OptimoveSuccessStateDelegate

    init(observer: OptimoveSuccessStateDelegate) {
        self.observer = observer
    }
}

@objc public protocol OptimoveSuccessStateDelegate: class {
    @objc func optimove(_ optimove: Optimove, didBecomeActiveWithMissingPermissions missingPermissions: [Int])
}

final class DeprecatedStateListener {

    private let stateDelegateQueue = DispatchQueue(label: "com.optimove.sdk_state_delegates")
    private var swiftStateDelegates: [ObjectIdentifier: OptimoveSuccessStateListenerWrapper] = [:]
    private var objcStateDelegate: [ObjectIdentifier: OptimoveSuccessStateDelegateWrapper] = [:]

    func registerSuccessStateListener(optimove: Optimove, listener: OptimoveSuccessStateListener) {
        if RunningFlagsIndication.isSdkRunning {
            listener.optimove(optimove, didBecomeActiveWithMissingPermissions: [])
            return
        }
        stateDelegateQueue.async {
            self.swiftStateDelegates[ObjectIdentifier(listener)] = OptimoveSuccessStateListenerWrapper(observer: listener)
        }
    }

    func unregisterSuccessStateListener(optimove: Optimove, listener: OptimoveSuccessStateListener) {
        stateDelegateQueue.async {
            self.swiftStateDelegates[ObjectIdentifier(listener)] = nil
        }
    }

    func onInitializationSuccessfully(_ optimove: Optimove) {
        swiftStateDelegates.values.forEach { (wrapper) in
            wrapper.observer?.optimove(optimove, didBecomeActiveWithMissingPermissions: [])
        }
        objcStateDelegate.values.forEach { (wrapper) in
            wrapper.observer.optimove(optimove, didBecomeActiveWithMissingPermissions: [])
        }
    }

}
