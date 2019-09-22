//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UIKit.UIApplication

protocol ResignActiveSubscriber {
    func onResignActive()
}

final class ResignActiveObserver: DeviceStateObservable {

    private let subscriber: ResignActiveSubscriber
    private var willResignActiveToken: NSObjectProtocol?

    init(subscriber: ResignActiveSubscriber) {
        self.subscriber = subscriber
    }

    func observe() {
        willResignActiveToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [subscriber] (_) in
            subscriber.onResignActive()
        }
    }

}
