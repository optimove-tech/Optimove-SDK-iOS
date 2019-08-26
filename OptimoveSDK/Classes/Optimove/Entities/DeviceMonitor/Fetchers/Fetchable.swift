//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol Fetchable {
    func fetch(completion: @escaping ResultBlockWithBool)
}
