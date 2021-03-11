//  Copyright © 2021 Optimove. All rights reserved.

public extension Set {

    func map<U>(transform: (Element) -> U) -> Set<U> {
        return Set<U>(self.lazy.map(transform))
    }

}
