//
//  Registrar.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

protocol RegistrationProtocol
{
    mutating func register()
    mutating func unregister(didComplete: @escaping ResultBlock)
}

protocol OptProtocol
{
    mutating func optIn()
    mutating func optOut()
}

class Registrar
{
    enum Category
    {
        case registration
        case opt
    }
    //MARK: - Internal Variables
    var registrationEndPoint: String
    var reportEndPoint: String
    
    //MARK: - Constructor
    init(optipushMetaData:OptipushMetaData)
    {
        Optimove.sharedInstance.logger.debug("Start Initialize Registrar")
        self.registrationEndPoint   = optipushMetaData.registrationServiceRegistrationEndPoint
        self.reportEndPoint         = optipushMetaData.registrationServiceOtherEndPoint
        Optimove.sharedInstance.logger.debug("Finish Initialize Registrar")
    }
    
    //MARK: - Private Methods
    
    private  func optInOutVisitor(state:State.Opt)
    {
         Optimove.sharedInstance.logger.debug("Visitor Opt InOut")
        if let json = RegistrationRequestComposer.composeOptInOutVisitorJSON(forState: state)
        {
            optimoveRegistrationRequest(type: .opt ,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForOptInOutVisitor())
            {
                UserInSession.shared.isOptRequestSuccess = true
            }
        }
    }
    
    private  func optInOutCustomer(state:State.Opt)
    {
        Optimove.sharedInstance.logger.debug("Customr Opt InOut")
        if let json = RegistrationRequestComposer.composeOptInOutCustomerJSON(forState: state)
        {
            optimoveRegistrationRequest(type: .opt,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForOptInOutCustomer())
            {
                UserInSession.shared.isOptRequestSuccess = true
            }
        }
    }
    
    
    private func registerVisitor()
    {
        Optimove.sharedInstance.logger.debug("Register visitor to MBAAS")
        if let json = RegistrationRequestComposer.composeRegisterVisitor()
        {
            UserInSession.shared.isRegistrationSuccess = false
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForRegisterVisitor())
            {
                UserInSession.shared.isRegistrationSuccess = true
            }
        }
    }
    private func registerCustomer()
    {
        Optimove.sharedInstance.logger.debug("Register customer to MBAAS")
        if let json = RegistrationRequestComposer.composeRegisterCustomer()
        {
            UserInSession.shared.isRegistrationSuccess = false
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForRegisterCustomer())
            {
                UserInSession.shared.isRegistrationSuccess = true
            }
        }
    }
    
    private func unregisterVisitor(didComplete:@escaping ResultBlock)
    {
        Optimove.sharedInstance.logger.debug("Unregister visitor from MBAAS")
        if let json = RegistrationRequestComposer.composeUnregisterVisitor()
        {
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForUnregisterVisitor(),
                                        didComplete: didComplete)
        }
    }
    
    private func unRegisterCustomer(didComplete: @escaping ResultBlock)
    {
        Optimove.sharedInstance.logger.debug("Unregister visitor from MBAAS")
        if let json = RegistrationRequestComposer.composeUnregisterCustomerJSON()
        {
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: OptimoveRegistrationApiPaths.pathForUnregisterCustomer(),
                                        didComplete: didComplete)
        }
    }
    
    
    
    
    private func optimoveRegistrationRequest(type: Registrar.Category,
                                                      json:Data,
                                                      path: String,
                                                      didComplete: ResultBlock? = nil)
    {
        func generateRegistrationSessionDataTask(fromRequest request:URLRequest) -> URLSessionDataTask
        {
            let task = URLSession.shared.dataTask(with: request, completionHandler:
            { (data, response, error) in
                if error != nil || (response as? HTTPURLResponse)?.statusCode != 200
                {
                    Optimove.sharedInstance.logger.severe("Registration request failed \(error.debugDescription)")
                    storeJSONInFileSystem()
                }
                else
                {
                    Optimove.sharedInstance.logger.debug("Registration request succeed")
                    markFileAsDone()
                    Optimove.sharedInstance.logger.debug("\(String.init(data: data ?? Data(), encoding: .utf8)!)")
        
                    didComplete?()
                }
            })
            return task
        }
        
        let endPoint = type == .registration ? registrationEndPoint : reportEndPoint
        
        if let url  = URL(string: endPoint+path)
        {
            let request = NetworkManager.generateRequest(toUrl: url,json: json)
            Optimove.sharedInstance.logger.error("Send request to \(endPoint+path)")
            Optimove.sharedInstance.logger.debug("\(String(data:json , encoding:.utf8) ?? "no data" )")
            let task = generateRegistrationSessionDataTask(fromRequest: request)
            task.resume()
        }
        
        func storeJSONInFileSystem()
        {
            Optimove.sharedInstance.logger.debug("Storing \(path) in disk")
            var actionFile = ""
            switch path
            {
            case OptimoveRegistrationApiPaths.pathForRegisterCustomer():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = true
                actionFile = "register_data.json"
            case OptimoveRegistrationApiPaths.pathForUnregisterVisitor():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = true
                actionFile = "unregister_data.json"
            case OptimoveRegistrationApiPaths.pathForOptInOutVisitor():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForOptInOutCustomer():
                UserInSession.shared.hasOptInOutJsonFile = true
                actionFile = "opt_in_out_data.json"
            default:
                return
            }
            OptimoveFileManager.shared.writeRegistrationFile(fileName:actionFile, withData: json)
        }
        
        
        func markFileAsDone()
        {
            var actionFile = ""
            switch path
            {
            case OptimoveRegistrationApiPaths.pathForRegisterCustomer():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = false
                actionFile = "register_data.json"
            case OptimoveRegistrationApiPaths.pathForUnregisterVisitor():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = false
                actionFile = "unregister_data.json"
            case OptimoveRegistrationApiPaths.pathForOptInOutVisitor():
                fallthrough
            case OptimoveRegistrationApiPaths.pathForOptInOutCustomer():
                UserInSession.shared.hasOptInOutJsonFile = false
                actionFile = "opt_in_out_data.json"
            default:
                return
            }
            
            let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
            if FileManager.default.fileExists(atPath: actionURL.path)
            {
                do
                {
                    try FileManager.default.removeItem(at: actionURL)
                    Optimove.sharedInstance.logger.debug("Deleting succeeded\n location: \(actionURL.path)")
                }
                catch
                {
                    Optimove.sharedInstance.logger.severe("Deleting failed\n location: \(actionURL.path)")
                }
            }
        }
    }
    
    //MARK: - Internal Methods
    func retryFailedOperationsIfExist()
    {
        let isVisitor = UserInSession.shared.customerID == nil ? true : false
        
        if UserInSession.shared.hasUnregisterJsonFile
        {
            let actionFile = "unregister_data.json"
            let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
            do
            {
                let json  = try Data.init(contentsOf: actionURL)
                
                let path = isVisitor ? OptimoveRegistrationApiPaths.pathForUnregisterVisitor() : OptimoveRegistrationApiPaths.pathForUnregisterCustomer()
                Optimove.sharedInstance.logger.debug("Try to send unregistration request from disk")
                optimoveRegistrationRequest(type: .registration,
                                            json: json,
                                            path: path)
            }
            catch { return }
        }
        if let hasRegisterJSONFile = UserInSession.shared.hasRegisterJsonFile
        {
            if hasRegisterJSONFile
            {
                let actionFile = "register_data.json"
                let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
                do
                {
                    let json  = try Data.init(contentsOf: actionURL)
                    
                    let path = isVisitor ? OptimoveRegistrationApiPaths.pathForRegisterVisitor() : OptimoveRegistrationApiPaths.pathForRegisterCustomer()
                    Optimove.sharedInstance.logger.debug("Try to send registration request from disk")
                    
                    
                    UserInSession.shared.isRegistrationSuccess = false
                    optimoveRegistrationRequest(type: .registration,
                                                json: json,
                                                path: path)
                    {
                        UserInSession.shared.isRegistrationSuccess = true
                    }
                }
                catch { return }
            }
        }
        if UserInSession.shared.hasOptInOutJsonFile
        {
            
            let actionFile = "opt_in_out_data.json"
            let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
            
            do
            {
                let json  = try Data.init(contentsOf: actionURL)
                let path = isVisitor ? OptimoveRegistrationApiPaths.pathForOptInOutVisitor() : OptimoveRegistrationApiPaths.pathForOptInOutCustomer()
                Optimove.sharedInstance.logger.debug("Try to send opt request from disk")
                optimoveRegistrationRequest(type: .opt, json: json, path: path)
            }
            catch { return }
        }
    }
}

extension Registrar: RegistrationProtocol
{
    func register()
    {
        CustomerID == nil ? registerVisitor() : registerCustomer()
    }
    
    func unregister(didComplete:@escaping ResultBlock)
    {
        CustomerID == nil ? unregisterVisitor(didComplete: didComplete) : unRegisterCustomer(didComplete: didComplete)
    }
}

extension Registrar : OptProtocol
{
    func optIn()
    {
        CustomerID == nil ? optInOutVisitor(state: .optIn) : optInOutCustomer(state: .optIn)
        UserInSession.shared.isOptIn = true
    }
    
    func optOut()
    {
        CustomerID == nil ? optInOutVisitor(state: .optOut) : optInOutCustomer(state: .optOut)
        UserInSession.shared.isOptIn = false
    }
}
