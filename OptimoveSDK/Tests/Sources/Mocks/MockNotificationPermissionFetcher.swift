//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class MockNotificationPermissionFetcher: NotificationPermissionFetcher {

    var permitted: Bool = true

    func fetch(completion: @escaping ResultBlockWithBool) {
        completion(permitted)
    }

}
