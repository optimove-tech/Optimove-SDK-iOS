import Foundation

struct OptimoveSuccessStateListenerWrapper {
    weak var observer: OptimoveSuccessStateListener?
}

public protocol OptimoveSuccessStateListener: class {
    func optimove(
        _ optimove: Optimove,
        didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]
    )
}

class OptimoveSuccessStateDelegateWrapper {
    var observer: OptimoveSuccessStateDelegate

    init(observer: OptimoveSuccessStateDelegate) {
        self.observer = observer
    }
}

@objc public protocol OptimoveSuccessStateDelegate: class {
    @objc func optimove(_ optimove: Optimove, didBecomeActiveWithMissingPermissions missingPermissions: [Int])
}
