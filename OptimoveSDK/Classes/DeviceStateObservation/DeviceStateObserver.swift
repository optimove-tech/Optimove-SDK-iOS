//  Copyright © 2019 Optimove. All rights reserved.

protocol DeviceStateObservable {
    func observe()
}

final class DeviceStateObserver {

    private let observers: [DeviceStateObservable]

    init(observers: [DeviceStateObservable]) {
        self.observers = observers
    }

    func start() {
        observers.forEach { $0.observe() }
    }

}
