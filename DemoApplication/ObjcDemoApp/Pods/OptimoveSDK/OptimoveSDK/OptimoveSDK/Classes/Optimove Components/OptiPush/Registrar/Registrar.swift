//
//  Registrar.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

protocol RegistrationProtocol: class {
    func register()
    func unregister(didComplete: @escaping ResultBlockWithBool)
    func optIn()
    func optOut()
    func retryFailedOperationsIfExist()
}

class Registrar {
    enum MbaasRequestType: String {
        case register = "register"
        case unregister = "unregister"
        case optIn = "opt in"
        case optOut = "opt out"
    }

    // MARK: - Internal Variables
    private var registrationEndPoint: String
    private var reportEndPoint: String

    // MARK: - Constructor
    init(optipushMetaData: OptipushMetaData) {
        OptiLoggerMessages.logRegistrarInitializtionStart()
        self.registrationEndPoint = optipushMetaData.registrationServiceRegistrationEndPoint
        if registrationEndPoint.last != "/" {
            registrationEndPoint.append("/")
        }
        self.reportEndPoint = optipushMetaData.registrationServiceOtherEndPoint
        if reportEndPoint.last != "/" {
            reportEndPoint.append("/")
        }
        OptiLoggerMessages.logRegistrarInitializtionFinish()
    }

    // MARK: - Private Methods

    private func backupRequest(_ mbaasRequestBody: MbaasRequestBody) {
        let path = getStoragePath(for: mbaasRequestBody.operation)
        if let json = mbaasRequestBody.toMbaasJsonBody() {
            OptimoveFileManager.save(data: json, toFileName: path)
        } else {
            OptiLoggerMessages.logMbaasRequestEncodeError(mbaasRequestBody: mbaasRequestBody.description)
        }
    }

    private func clearBackupRequest(_ operation: MbaasOperations) {
        let path = getStoragePath(for: operation)
        OptimoveFileManager.delete(file: path, isInSharedContainer: false)
    }

    private func getMbaasPath(for userPushToken: MbaasRequestBody) -> String {
        let suffix = userPushToken.publicCustomerId == nil ? "Visitor" : "Customer"
        switch userPushToken.operation {
        case .registration:
            return  "\(registrationEndPoint)register\(suffix)"
        case .unregistration:
            return "\(reportEndPoint)unregister\(suffix)"
        case .optIn: fallthrough
        case .optOut:
            return "\(reportEndPoint)optInOut\(suffix)"
        }
    }

    private func getStoragePath(for operation: MbaasOperations) -> String {
        switch operation {
        case .registration:
            return "register_data.json"
        case .unregistration:
            return "unregister_data.json"
        case .optIn: fallthrough
        case .optOut:
            return "opt_in_out_data.json"
        }
    }

    // MARK: - Internal Methods
    private func setSuccesFlag(succeed: Bool, for operation: MbaasOperations) {
        switch operation {
        case .optIn, .optOut:
            OptimoveUserDefaults.shared.isOptRequestSuccess = succeed
        case .registration:
            OptimoveUserDefaults.shared.isRegistrationSuccess = succeed
        case .unregistration:
            OptimoveUserDefaults.shared.isUnregistrationSuccess = succeed
        }
    }

    private func retryFailedOperation(_ operation: MbaasOperations, using json: Data) {
        guard let url = UserDefaults.standard.url(forKey: "\(operation.rawValue)_endpoint") else { // TODO Clean this up - no literal constants should be here
            // TODO Handle corrupt state - should probably just delete the retry backup
            return
        }
        var path: URL?
        if url.path == "/registerCustomer" || url.path == "/registerVisitor" {
            path = URL(string: (self.registrationEndPoint + url.path).replacingOccurrences(of: "//", with: "/"))
        } else {
            path = URL(string: (self.reportEndPoint + url.path).replacingOccurrences(of: "//", with: "/"))
        }

        guard path != nil else {
            OptiLoggerMessages.logMbaasRequestUrlEncodeError()
            return
        }
        OptiLoggerMessages.logSendRetryTo(path: path!.path)
        NetworkManager.post(toUrl: path!, json: json) { (_, error) in
            guard error == nil else {
                OptiLoggerMessages.logRetryFailed()
                return
            }
            self.handleSuccessMbaasRequest(of: operation, to: url)
            if operation == .unregistration {
                self.register()
            }
        }
    }

    func retryFailedOperationsIfExist() {
        if !OptimoveUserDefaults.shared.isUnregistrationSuccess {
            let path = getStoragePath(for: .unregistration)
            if let json = OptimoveFileManager.load(file: path, isInSharedContainer: false) {
                self.retryFailedOperation(.unregistration, using: json)
            }
        } else if !OptimoveUserDefaults.shared.isRegistrationSuccess {
            let path = getStoragePath(for: .registration)
            if let json = OptimoveFileManager.load(file: path, isInSharedContainer: false) {
                self.retryFailedOperation(.registration, using: json)
            }
        }
        if !OptimoveUserDefaults.shared.isOptRequestSuccess {
            let path = getStoragePath(for: .optIn) // optIn and optOut share the same backup file
            if let json = OptimoveFileManager.load(file: path, isInSharedContainer: false) {
                self.retryFailedOperation(.optIn, using: json)
            }
        }
    }
}

extension Registrar: RegistrationProtocol {
    func register() {
        let mbaasRequest = MbaasRequestBuilder(operation: .registration)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string: getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLoggerMessages.logJsonBuildFailure(mbaasRequestOperation: mbaasRequest.operation.rawValue)
            return
        }
        OptiLoggerMessages.logSendMbaasRequest(url: url, json: String(decoding: json, as: UTF8.self))
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            self.handleResponseFromMbaas(ofRequest: mbaasRequest, withData: data, error: error, url: url)
        }
    }

    func unregister(didComplete: @escaping ResultBlockWithBool) {
        let mbaasRequest = MbaasRequestBuilder(operation: .unregistration).setUserInfo(visitorId: VisitorID, customerId: CustomerID).build()
        let url = URL(string: getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLoggerMessages.logJsonBuildFailure(mbaasRequestOperation: mbaasRequest.operation.rawValue)
            return
        }
        OptiLoggerMessages.logSendMbaasRequest(url: url, json: String(decoding: json, as: UTF8.self))
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            self.handleResponseFromMbaas(ofRequest: mbaasRequest, withData: data, error: error, url: url, didComplete: didComplete)
        }
    }

    func optIn() {
        let mbaasRequest = MbaasRequestBuilder(operation: .optIn)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string: getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLoggerMessages.logJsonBuildFailure(mbaasRequestOperation: mbaasRequest.operation.rawValue)
            return
        }
        OptiLoggerMessages.logSendMbaasRequest(url: url, json: String(decoding: json, as: UTF8.self))
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            self.handleResponseFromMbaas(ofRequest: mbaasRequest, withData: data, error: error, url: url)
        }
    }

    func optOut() {
        let mbaasRequest = MbaasRequestBuilder(operation: .optOut)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string: getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLoggerMessages.logJsonBuildFailure(mbaasRequestOperation: mbaasRequest.operation.rawValue)
            return
        }
        OptiLoggerMessages.logSendMbaasRequest(url: url, json: String(decoding: json, as: UTF8.self))
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            self.handleResponseFromMbaas(ofRequest: mbaasRequest, withData: data, error: error, url: url)
        }
    }

    func handleResponseFromMbaas(ofRequest mbaasRequest: MbaasRequestBody, withData data: Data?, error: OptimoveError?, url: URL, didComplete: ((Bool) -> Void)? = nil) {
        //If the error code indicate a user error, there is no sense to retry this request again
        if let error = error, (error == .badRequest || error == .notFound || error == .gone) {
            OptiLoggerMessages.logMbaasRequestError(mbaasRequestOperation: mbaasRequest.operation.rawValue, errorDescription: "\(error.localizedDescription)")
            didComplete?(false)
            return
        }
        guard error == nil else {
            OptiLoggerMessages.logMbaasRequestError(mbaasRequestOperation: mbaasRequest.operation.rawValue, errorDescription: error.debugDescription)
            self.handleFailedMbaasRequest(of: mbaasRequest, to: url)
            didComplete?(false)
            return
        }
        OptiLoggerMessages.logMbaasResponse(mbaasRequestOperation: mbaasRequest.operation.rawValue, response: String(decoding: data!, as: UTF8.self))
        if mbaasRequest.operation == .optIn {
            OptimoveUserDefaults.shared.isMbaasOptIn = true
        }
        self.handleSuccessMbaasRequest(of: mbaasRequest.operation, to: url)
        didComplete?(true)
    }

    private func handleFailedMbaasRequest(of mbaasRequest: MbaasRequestBody, to url: URL) {
        self.backupRequest(mbaasRequest)
        UserDefaults.standard.set(url.path, forKey: "\(mbaasRequest.operation.rawValue)_endpoint") // TODO Clean this up - no literal constants should be here
        self.setSuccesFlag(succeed: false, for: mbaasRequest.operation)
    }

    private func handleSuccessMbaasRequest(of operation: MbaasOperations, to url: URL) {
        self.clearBackupRequest(operation)
        UserDefaults.standard.removeObject(forKey: "\(operation.rawValue)_endpoint") // TODO Clean this up - no literal constants should be here
        self.setSuccesFlag(succeed: true, for: operation)
    }
}
