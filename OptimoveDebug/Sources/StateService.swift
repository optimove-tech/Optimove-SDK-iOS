//  Copyright © 2024 Optimove. All rights reserved.

import Foundation
import OptimoveCore
@testable import OptimoveSDK

public final class StateService {
    public enum State {
        case app_version
        case sdk_version
        case installation
        case tenant
        case initial_visitor
        case customer
        case update_visitor
        case email
    }

    private enum Constants {
        static let undefined = ""
    }

    public static var shared: StateService = .init()

    private let storage: any OptimoveStorage

    private init() {
        do {
            storage = try StorageFacade(
                standardStorage: UserDefaults.optimove(),
                appGroupStorage: UserDefaults.optimoveAppGroup(),
                inMemoryStorage: InMemoryStorage(),
                fileStorage: FileStorageImpl(
                    persistentStorageURL: FileManager.optimoveURL(),
                    temporaryStorageURL: FileManager.temporaryURL()
                )
            )
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public func getState(_ state: State) -> String {
        switch state {
        case .app_version:
            return "\(ApplicationInfo.version) build: \(ApplicationInfo.build)"
        case .sdk_version:
            return Optimove.version
        case .installation:
            return storage.installationID ?? Constants.undefined
        case .tenant:
            guard let tenantID = storage.tenantID else { return Constants.undefined }
            return String(tenantID)
        case .initial_visitor:
            return storage.initialVisitorId ?? Constants.undefined
        case .customer:
            return storage.customerID ?? Constants.undefined
        case .email:
            return storage.userEmail ?? Constants.undefined
        case .update_visitor:
            return storage.visitorID ?? Constants.undefined
        }
    }

    public subscript(state: State) -> String {
        return StateService.shared.getState(state)
    }
}
