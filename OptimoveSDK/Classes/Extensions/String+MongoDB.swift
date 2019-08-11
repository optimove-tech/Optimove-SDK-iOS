//  Copyright © 2019 Optimove. All rights reserved.

extension String {

    func setAsMongoKey() -> String {
        return self.replacingOccurrences(of: ".", with: "_")
    }

}
