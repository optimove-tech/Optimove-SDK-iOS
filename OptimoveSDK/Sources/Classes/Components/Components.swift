//  Copyright © 2019 Optimove. All rights reserved.

protocol CommonComponent {
    func serve(_: CommonOperation) throws
}

protocol OptistreamComponent {
    func serve(_: OptistreamOperation) throws
}
