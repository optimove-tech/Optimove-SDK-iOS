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
    let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                       in: .userDomainMask)[0]
    lazy var optimoveSDKDirectory = appSupportDirectory.appendingPathComponent("OptimoveSDK")
    
    
    enum Category
    {
        case registration
        case opt
    }
    //MARK: - Internal Variables
    var registrationEndPoint: String
    var reportEndPoint: String
    
    //MARK: - Constructor
    init(registrationEndPoint: String, reportEndPoint: String)
    {
        self.registrationEndPoint   = registrationEndPoint
        self.reportEndPoint         = reportEndPoint
    }
    
    
    //MARK: - Private Methods
    
    private mutating func optInOutVisitor(state:State.Opt)
    {
        LogManager.reportToConsole("Visitor Opt InOut")
        if let json = JSONComposer.composeOptInOutVisitorJSON(forState: state)
        {
            if state == .optIn
            {
                Optimove.sharedInstance.report(event: OptipushOptIn())
            }
            else
            {
                Optimove.sharedInstance.report(event: OptipushOptOut())
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
        LogManager.reportToConsole("Customr Opt InOut")
        if let json = JSONComposer.composeOptInOutCustomerJSON(forState: state)
        {
            if state == .optIn
            {
                Optimove.sharedInstance.report(event: OptipushOptIn())
            }
            else
            {
                Optimove.sharedInstance.report(event: OptipushOptOut())
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
        
        LogManager.reportToConsole("Register visitor to MBAAS")
        
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
        LogManager.reportToConsole("Register customer to MBAAS")
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
        LogManager.reportToConsole("Unregister visitor to MBAAS")
        
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
        LogManager.reportToConsole("Unregister customer to MBAAS")
        
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
                //                let error = OptimoveError.error
                if error != nil
                {
                    LogManager.reportFailureToConsole("Registration request failed")
                    LogManager.reportError(error: error)
                    storeJSONInFileSystem()
                }
                else
                {
                    LogManager.reportSuccessToConsole("Registration request succeed")
                    markFileAsDone()
                    LogManager.reportData(data!)
                    didComplete?()
                }
            })
            return task
        }
        
        let endPoint = type == .registration ? registrationEndPoint : reportEndPoint
        
        if let url  = URL(string: endPoint+path)
        {
            let request = generateRequest(toUrl: url,json: json)
            LogManager.reportToConsole("Send request to \(endPoint+path)")
            LogManager.reportData(json)
            let task = generateRegistrationSessionDataTask(fromRequest: request)
            task.resume()
        }
        
        func storeJSONInFileSystem()
        {
            LogManager.reportToConsole("Storing \(path) in disk!!" )
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
            do
            {
                try FileManager.default.createDirectory(at: optimoveSDKDirectory, withIntermediateDirectories: true)
                let fileURL = optimoveSDKDirectory.appendingPathComponent(actionFile)
                let success = FileManager.default.createFile(atPath: fileURL.path, contents: json, attributes: nil)
                LogManager.reportToConsole("Storing status is \(success)\n location: \(optimoveSDKDirectory.path)")
            }
            catch
            {
                LogManager.reportError(error: OptimoveError.cantStoreFileInLocalStorage)
                return
            }
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
            
            let actionURL = optimoveSDKDirectory.appendingPathComponent(actionFile)
            if FileManager.default.fileExists(atPath: actionURL.path)
            {
                do
                {
                    try FileManager.default.removeItem(at: actionURL)
                    LogManager.reportSuccessToConsole("Deleting succeeded\n location: \(actionURL.path)")
                }
                catch
                {
                    LogManager.reportFailureToConsole("Deleting failed\n location: \(actionURL.path)")
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
            let actionURL = optimoveSDKDirectory.appendingPathComponent(actionFile)
            do
            {
                let json  = try Data.init(contentsOf: actionURL)
                
                let path = isVisitor ? NetworkAPIPaths.pathForUnregisterVisitor() : NetworkAPIPaths.pathForUnregisterCustomer()
                LogManager.reportToConsole("Try to send unregistration request from disk")
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
                let actionURL = optimoveSDKDirectory.appendingPathComponent(actionFile)
                do
                {
                    let json  = try Data.init(contentsOf: actionURL)
                    
                    let path = isVisitor ? NetworkAPIPaths.pathForRegisterVisitor() : NetworkAPIPaths.pathForRegisterCustomer()
                    LogManager.reportToConsole("Try to send registration request from disk")
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
            let actionURL = optimoveSDKDirectory.appendingPathComponent(actionFile)
            
            do
            {
                let json  = try Data.init(contentsOf: actionURL)
                let path = isVisitor ? NetworkAPIPaths.pathForOptInOutVisitor() : NetworkAPIPaths.pathForOptInOutCustomer()
                LogManager.reportToConsole("Try to send opt request from disk")
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
