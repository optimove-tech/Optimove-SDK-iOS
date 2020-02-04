//  Copyright © 2019 Optimove. All rights reserved.

final class Chain {

    private(set) var next: Node

    init(next: Node) {
        self.next = next
    }

}

protocol ChainMutator {
    func addNode(_: Node)
}
