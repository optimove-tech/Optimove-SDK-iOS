//
//  Registrar.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

protocol RegistrationProtocol:class
{
    func register()
    func unregister(didComplete: @escaping ResultBlockWithBool)
    func optIn()
    func optOut()
    func retryFailedOperationsIfExist()
}

class Registrar
{
    //MARK: - Internal Variables
    private var registrationEndPoint: String
    private var reportEndPoint: String
    
    //MARK: - Constructor
    init(optipushMetaData: OptipushMetaData)
    {
        OptiLogger.debug("Start Initialize Registrar")
        self.registrationEndPoint = optipushMetaData.registrationServiceRegistrationEndPoint
        if registrationEndPoint.last != "/"  {
            registrationEndPoint.append("/")
        }
        self.reportEndPoint = optipushMetaData.registrationServiceOtherEndPoint
        if reportEndPoint.last != "/"  {
            reportEndPoint.append("/")
        }
        OptiLogger.debug("Finish Initialize Registrar")
    }
    
    //MARK: - Private Methods
    
    private func backupRequest(_ mbaasRequestBody: MbaasRequestBody) {
        let path = getStoragePath(for: mbaasRequestBody.operation)
        if let json = mbaasRequestBody.toMbaasJsonBody() {
            OptimoveFileManager.save(data:json , toFileName: path)
        } else {
            OptiLogger.error("Could not encode user push token: \(mbaasRequestBody)")
        }
    }
    
    private func clearBackupRequest(_ operation: MbaasOperations) {
        let path = getStoragePath(for: operation)
        OptimoveFileManager.delete(file: path)
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
    
    //MARK: - Internal Methods
    private func setSuccesFlag(succeed: Bool, for operation:MbaasOperations)
    {
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
        
        OptiLogger.debug("send retry request to :\(url.path)")
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            guard error == nil else {
                OptiLogger.error("retry request failed, lets try next time...")
                return
            }
            self.handleSuccessMbaasRequest(of: operation, to: url)
            if operation == .unregistration {
                self.register()
            }
        }
    }
    
    func retryFailedOperationsIfExist() {
        if (!OptimoveUserDefaults.shared.isUnregistrationSuccess) {
            let path = getStoragePath(for: .unregistration)
            if let json = OptimoveFileManager.load(file: path) {
                self.retryFailedOperation(.unregistration, using: json)
            }
        } else if (!OptimoveUserDefaults.shared.isRegistrationSuccess) {
            let path = getStoragePath(for: .registration)
            if let json = OptimoveFileManager.load(file: path) {
                self.retryFailedOperation(.registration, using: json)
            }
        }
        if (!OptimoveUserDefaults.shared.isOptRequestSuccess) {
            let path = getStoragePath(for: .optIn) // optIn and optOut share the same backup file
            if let json = OptimoveFileManager.load(file: path) {
                self.retryFailedOperation(.optIn, using: json)
            }
        }
    }
}

extension Registrar: RegistrationProtocol
{
    func register()
    {
        let mbaasRequest = MbaasRequestBuilder(operation: .registration)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string:  getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLogger.error("could not build Json object of \(mbaasRequest.operation)")
            return
        }
        OptiLogger.debug("send request to \(url) with body: \(String(describing: String(data:json,encoding:.utf8)!))")
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            guard error == nil else {
                OptiLogger.error("registration error: \(String(describing: error?.localizedDescription))")
                self.handleFailedMbaasRequest(of: mbaasRequest, to: url)
                return
            }
            OptiLogger.debug("registration response: \(String(describing: String(data:data!,encoding:.utf8)))")
            self.handleSuccessMbaasRequest(of: mbaasRequest.operation, to: url)
        }
    }
    
    func unregister(didComplete: @escaping ResultBlockWithBool)
    {
        let mbaasRequest = MbaasRequestBuilder(operation: .unregistration).setUserInfo(visitorId: VisitorID, customerId: CustomerID).build()
        let url = URL(string:  getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLogger.error("could not build Json object of \(mbaasRequest.operation)")
            return
        }
        OptiLogger.debug("send request to \(url) with body: \(String(describing: String(data:json,encoding:.utf8)!))")
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            guard error == nil else {
                OptiLogger.error("unregistration error: \(String(describing: error?.localizedDescription))")
               self.handleFailedMbaasRequest(of: mbaasRequest, to: url)
                didComplete(false)
                return
            }
            OptiLogger.debug("unregistration response: \(String(describing: String(data:data!,encoding:.utf8)))")
            self.handleSuccessMbaasRequest(of: mbaasRequest.operation, to: url)
            didComplete(true)
        }
    }
    
    func optIn()
    {
        let mbaasRequest = MbaasRequestBuilder(operation: .optIn)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string:  getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLogger.error("could not build Json object of \(mbaasRequest.operation)")
            return
        }
        OptiLogger.debug("send request to \(url) with body: \(String(describing: String(data:json,encoding:.utf8)!))")
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            guard error == nil else {
                OptiLogger.error("opt in error: \(String(describing: error?.localizedDescription))")
                self.handleFailedMbaasRequest(of: mbaasRequest, to: url)
                return
            }
            OptiLogger.debug("opt in response: \(String(describing: String(data:data!,encoding:.utf8)))")
            OptimoveUserDefaults.shared.isMbaasOptIn = true
            self.handleSuccessMbaasRequest(of: mbaasRequest.operation, to: url)
        }
    }
    
    func optOut()
    {
        let mbaasRequest = MbaasRequestBuilder(operation: .optOut)
            .setUserInfo(visitorId: VisitorID, customerId: CustomerID)
            .build()
        let url = URL(string:  getMbaasPath(for: mbaasRequest))!
        guard let json = mbaasRequest.toMbaasJsonBody() else {
            OptiLogger.error("could not build Json object of \(mbaasRequest.operation)")
            return
        }
        OptiLogger.debug("send request to \(url) with body: \(String(describing: String(data:json,encoding:.utf8)!))")
        NetworkManager.post(toUrl: url, json: json) { (data, error) in
            guard error == nil else {
                OptiLogger.error("opt out error: \(String(describing: error?.localizedDescription))")
                self.handleFailedMbaasRequest(of: mbaasRequest, to: url)
                return
            }
            OptiLogger.debug("opt out response: \(String(describing: String(data:data!,encoding:.utf8)))")
            self.handleSuccessMbaasRequest(of: mbaasRequest.operation, to: url)
        }
    }
    
    private func handleFailedMbaasRequest(of mbaasRequest:MbaasRequestBody, to url: URL)
    {
        self.backupRequest(mbaasRequest)
        UserDefaults.standard.set(url, forKey: "\(mbaasRequest.operation.rawValue)_endpoint") // TODO Clean this up - no literal constants should be here
        self.setSuccesFlag(succeed: false, for: mbaasRequest.operation)
    }
    
    private func handleSuccessMbaasRequest(of operation: MbaasOperations, to url: URL)
    {
        self.clearBackupRequest(operation)
        UserDefaults.standard.removeObject(forKey: "\(operation.rawValue)_endpoint") // TODO Clean this up - no literal constants should be here
        self.setSuccesFlag(succeed: true, for: operation)
    }
}
