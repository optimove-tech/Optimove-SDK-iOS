//  Copyright © 2019 Optimove. All rights reserved.

protocol Tracker {
    func track(_ event: OptimoveEvent)
    func dispatch()
}
