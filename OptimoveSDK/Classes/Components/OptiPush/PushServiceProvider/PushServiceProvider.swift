//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol PushServiceProvider {
    func handleRegistration(apnsToken: Data)
}
