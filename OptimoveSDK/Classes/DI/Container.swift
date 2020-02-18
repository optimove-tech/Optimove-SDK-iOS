//  Copyright © 2020 Optimove. All rights reserved.

final class Container {

    private var serviceLocator: ServiceLocator?

    init(serviceLocator: ServiceLocator?) {
        self.serviceLocator = serviceLocator
    }

    @discardableResult
    func resolve<ReturnType>(_ invoker: @escaping (ServiceLocator) -> (ReturnType)) -> ReturnType? {
        if let serviceLocator = serviceLocator {
            return invoker(serviceLocator)
        }
        return nil
    }

}
