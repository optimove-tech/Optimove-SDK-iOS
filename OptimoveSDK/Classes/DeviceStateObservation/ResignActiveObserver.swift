//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UIKit.UIApplication

protocol ResignActiveSubscriber {
    func onResignActive()
}

final class ResignActiveObserver: DeviceStateObservable {

    private let subscriber: ResignActiveSubscriber

    init(subscriber: ResignActiveSubscriber) {
        self.subscriber = subscriber
    }

    func observe() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: self,
            queue: .main
        ) { [subscriber] (_) in
            subscriber.onResignActive()
        }
    }

}
