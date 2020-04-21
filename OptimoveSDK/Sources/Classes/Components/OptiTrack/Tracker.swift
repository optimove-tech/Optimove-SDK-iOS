//  Copyright © 2019 Optimove. All rights reserved.

protocol Tracker {
    func track(event: Event)
    func dispatch()
}
