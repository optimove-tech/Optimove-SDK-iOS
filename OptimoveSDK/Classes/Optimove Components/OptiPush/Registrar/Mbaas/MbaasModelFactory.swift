// Copiright 2019 Optimove

import Foundation

final class MbaasModelFactory {

    private let storage: OptimoveStorage
    private let processInfo: ProcessInfo
    private let device: Device.Type
    private let bundle: Bundle.Type

    init(storage: OptimoveStorage,
         processInfo: ProcessInfo,
         device: Device.Type,
         bundle: Bundle.Type) {
        self.storage = storage
        self.processInfo = processInfo
        self.device = device
        self.bundle = bundle
    }

    func createModel(for operation: MbaasOperation) throws -> BaseMbaasModel {
        switch operation {
        case .registration:
            return try createRegistrationModel()
        case .optIn:
            return try createDefaultModel(for: .optIn)
        case .optOut:
            return try createDefaultModel(for: .optOut)
        case .unregistration:
            return try createDefaultModel(for: .unregistration)
        }
    }

    private func createRegistrationModel() throws -> RegistartionMbaasModel {
        return RegistartionMbaasModel(
            isMbaasOptIn: storage.isMbaasOptIn ?? true,
            fcmToken: try storage.getFcmToken(),
            osVersion: processInfo.operatingSystemVersionOnlyString,
            tenantId: try storage.getSiteID(),
            userIdPayload: try createUserIdPayload(),
            deviceId: device.uuid,
            appNs: try bundle.getApplicationNameSpace().setAsMongoKey()
        )
    }

    private func createDefaultModel(for operation: MbaasOperation) throws -> MbaasModel {
        return MbaasModel(
            deviceId: device.uuid,
            appNs: try bundle.getApplicationNameSpace().setAsMongoKey(),
            operation: operation,
            tenantId: try storage.getSiteID(),
            userIdPayload: try createUserIdPayload()
        )
    }

    private func createUserIdPayload() throws -> BaseMbaasModel.UserIdPayload {
        do {
            return BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: try storage.getCustomerID(),
                    isConversion: storage.isFirstConversion,
                    initialVisitorId: try storage.getInitialVisitorId()
                )
            )
        } catch {
            return BaseMbaasModel.UserIdPayload.visitorID(try storage.getVisitorID())
        }
    }

}
