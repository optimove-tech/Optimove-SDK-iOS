//  Copyright © 2020 Optimove. All rights reserved.

/// The container is using for prevent an unexpected internal crash to affect on a tenant app.
final class Container {
    private var serviceLocator: ServiceLocator?

    init(serviceLocator: ServiceLocator?) {
        self.serviceLocator = serviceLocator
    }

    @discardableResult
    func resolve<ReturnType>(_ invoker: @escaping (ServiceLocator) throws -> (ReturnType)) -> ReturnType? {
        if let serviceLocator = serviceLocator {
            do {
                return try invoker(serviceLocator)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
        return nil
    }
}
