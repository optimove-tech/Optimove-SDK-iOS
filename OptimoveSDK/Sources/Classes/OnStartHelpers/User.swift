//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

final class User {
    let userID: String
    let visitorID: String

    init(userID: String) {
        self.userID = userID
        visitorID = userID.sha1().prefix(16).description.lowercased()
    }
}
