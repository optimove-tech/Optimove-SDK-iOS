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


struct Registrar
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
    
    private mutating func optInOutVisitor(state:State.Opt)
    {
         Optimove.sharedInstance.logger.debug("Visitor Opt InOut")
        if let json = JSONComposer.composeOptInOutVisitorJSON(forState: state)
        {
            if state == .optIn
            {
                Optimove.sharedInstance.internalReport(event: OptipushOptIn())
            }
            else
            {
                Optimove.sharedInstance.internalReport(event: OptipushOptOut())
            }
            optimoveRegistrationRequest(type: .opt ,
                                        json: json,
                                        path: NetworkAPIPaths.pathForOptInOutVisitor())
            {
                UserInSession.shared.isOptRequestSuccess = true
            }
        }
    }
    
    private mutating func optInOutCustomer(state:State.Opt)
    {
        Optimove.sharedInstance.logger.debug("Customr Opt InOut")
        if let json = JSONComposer.composeOptInOutCustomerJSON(forState: state)
        {
            if state == .optIn
            {
                Optimove.sharedInstance.internalReport(event: OptipushOptIn())
            }
            else
            {
                Optimove.sharedInstance.internalReport(event: OptipushOptOut())
            }
            optimoveRegistrationRequest(type: .opt,
                                        json: json,
                                        path: NetworkAPIPaths.pathForOptInOutCustomer())
            {
                UserInSession.shared.isOptRequestSuccess = true
            }
        }
    }
    
    
    private mutating func registerVisitor()
    {
        Optimove.sharedInstance.logger.debug("Register visitor to MBAAS")
        if let json = JSONComposer.composeRegisterVisitor()
        {
            UserInSession.shared.isRegistrationSuccess = false
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: NetworkAPIPaths.pathForRegisterVisitor())
            {
                UserInSession.shared.isRegistrationSuccess = true
            }
        }
    }
    private mutating func registerCustomer()
    {
        Optimove.sharedInstance.logger.debug("Register customer to MBAAS")
        if let json = JSONComposer.composeRegisterCustomer()
        {
            UserInSession.shared.isRegistrationSuccess = false
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: NetworkAPIPaths.pathForRegisterCustomer())
            {
                UserInSession.shared.isRegistrationSuccess = true
            }
        }
    }
    
    private mutating func unregisterVisitor(didComplete:@escaping ResultBlock)
    {
        Optimove.sharedInstance.logger.debug("Unregister visitor from MBAAS")
        if let json = JSONComposer.composeUnregisterVisitor()
        {
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: NetworkAPIPaths.pathForUnregisterVisitor(),
                                        didComplete: didComplete)
        }
    }
    
    private mutating func unRegisterCustomer(didComplete: @escaping ResultBlock)
    {
        Optimove.sharedInstance.logger.debug("Unregister visitor from MBAAS")
        if let json = JSONComposer.composeUnregisterCustomerJSON()
        {
            optimoveRegistrationRequest(type: .registration,
                                        json: json,
                                        path: NetworkAPIPaths.pathForUnregisterCustomer(),
                                        didComplete: didComplete)
        }
    }
    
    private func generateRequest(toUrl url:URL,json:Data) -> URLRequest
    {
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = HttpMethod.post.rawValue
        request.httpBody = json
        request.setValue(MediaType.json.rawValue,
                         forHTTPHeaderField: HttpHeader.contentType.rawValue)
        return request
    }
    
    
    private mutating func optimoveRegistrationRequest(type: Registrar.Category,
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
            let request = generateRequest(toUrl: url,json: json)
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
            case NetworkAPIPaths.pathForRegisterCustomer():
                fallthrough
            case NetworkAPIPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = true
                actionFile = "register_data.json"
            case NetworkAPIPaths.pathForUnregisterVisitor():
                fallthrough
            case NetworkAPIPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = true
                actionFile = "unregister_data.json"
            case NetworkAPIPaths.pathForOptInOutVisitor():
                fallthrough
            case NetworkAPIPaths.pathForOptInOutCustomer():
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
            case NetworkAPIPaths.pathForRegisterCustomer():
                fallthrough
            case NetworkAPIPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = false
                actionFile = "register_data.json"
            case NetworkAPIPaths.pathForUnregisterVisitor():
                fallthrough
            case NetworkAPIPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = false
                actionFile = "unregister_data.json"
            case NetworkAPIPaths.pathForOptInOutVisitor():
                fallthrough
            case NetworkAPIPaths.pathForOptInOutCustomer():
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
    mutating func retryFailedOperationsIfExist()
    {
        let isVisitor = UserInSession.shared.customerID == nil ? true : false
        
        if UserInSession.shared.hasUnregisterJsonFile
        {
            let actionFile = "unregister_data.json"
            let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
            do
            {
                let json  = try Data.init(contentsOf: actionURL)
                
                let path = isVisitor ? NetworkAPIPaths.pathForUnregisterVisitor() : NetworkAPIPaths.pathForUnregisterCustomer()
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
                    
                    let path = isVisitor ? NetworkAPIPaths.pathForRegisterVisitor() : NetworkAPIPaths.pathForRegisterCustomer()
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
                let path = isVisitor ? NetworkAPIPaths.pathForOptInOutVisitor() : NetworkAPIPaths.pathForOptInOutCustomer()
                Optimove.sharedInstance.logger.debug("Try to send opt request from disk")
                optimoveRegistrationRequest(type: .opt, json: json, path: path)
            }
            catch { return }
        }
    }
}

extension Registrar: RegistrationProtocol
{
    mutating func register()
    {
        CustomerID == nil ? registerVisitor() : registerCustomer()
    }
    
    mutating func unregister(didComplete:@escaping ResultBlock)
    {
        CustomerID == nil ? unregisterVisitor(didComplete: didComplete) : unRegisterCustomer(didComplete: didComplete)
    }
}

extension Registrar : OptProtocol
{
    mutating func optIn()
    {
        CustomerID == nil ? optInOutVisitor(state: .optIn) : optInOutCustomer(state: .optIn)
        UserInSession.shared.isOptIn = true
    }
    
    mutating func optOut()
    {
        CustomerID == nil ? optInOutVisitor(state: .optOut) : optInOutCustomer(state: .optOut)
        UserInSession.shared.isOptIn = false
    }
}
