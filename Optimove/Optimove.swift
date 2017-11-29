//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications

public enum OptimoveError: Error
{
    case error
    case noNetwork
    case noPermissions
    case invalidEvent
    case mandatoryParameterMissing
    case cantStoreFileInLocalStorage
}

/**
 The entry point of Optimove SDK.
 Initialize and configure Optimove using Optimove.sharedOptimove.configure.
 */
public final class Optimove : OptimoveStateDelegate
{
    public var id: Int = -1
    
    //MARK: - Attributes
    var optiPush        : Optipush?
    var optitrack       : OptiTrack?
    var monitor         : MonitorOptimoveState
    var eventValidator  : EventValidator?
    var notificationHandler: OptimoveNotificationHandler
    
    var pendingNotificationReposnses:[UNNotificationResponse] = []
    
    public static let sharedInstance  = Optimove()
    
    //MARK: - Constructor
    private init()
    {
        notificationHandler = OptimoveNotificationHandler()
        monitor = MonitorOptimoveState()
        monitor.register(stateDelegate: self)
    }
    
    /// Validate and send the event to Optitrack component
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be NULL.
    private func handleReport(event:OptimoveEvent, completionHandler: ResultBlockWithError?)
    {
        guard let eventValidator = eventValidator else
        {
            if completionHandler != nil
            {
                completionHandler!(.error)
            }
            return
        }
        eventValidator.validate(event: event)
        { [weak self](error) in
            if error == nil
            {
                guard let eventConfig = eventValidator.eventsConfigs[event.name] else { return }
                self?.optitrack?.report(event: event,withConfigs: eventConfig)
                {
                    if completionHandler != nil
                    {
                        completionHandler!(nil)
                    }
                }
            }
            else
            {
                if completionHandler != nil
                {
                    completionHandler!(error)
                }
            }
        }
    }
    //MARK: - Internal API
    
    /// validate the state of the sdk and if available internally sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be nil.
    func report(event:OptimoveEvent, completionHandler: ResultBlockWithError? = nil)
    {
        guard  monitor.isComponentInternallyAvailable(.optiTrack) else
        {
            completionHandler?(OptimoveError.noPermissions)
            return
        }
        handleReport(event: event,
                     completionHandler: completionHandler)
    }
    
    func dispatchNow()
    {
        optitrack?.dispatchNow()
    }
    
    // MARK: - Public API
    
    /// validate the permissions of the client to use optitrack component and if permit sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be nil.
    public func reportEvent(event:OptimoveEvent, completionHandler: ResultBlockWithError?)
    {
        guard monitor.isComponentPubliclyAvailable(.optiTrack) else
        {
            completionHandler?(.noPermissions)
            return
        }
        handleReport(event: event,
                     completionHandler: completionHandler)
    }
    
    
    
    /// validate the permissions of the client to use optitrack component and if permit validate the userID content and sends:
    /// - conversion request to the DB
    /// - new customer registraion to the registration end point
    ///
    /// - Parameter userID: the client unique identifier
    public func set(userID: String)
    {
        guard !userID.isEmpty,
            !userID.contains("undefine"),
            !(userID == "null")
            else {return}
        if UserInSession.shared.isFirstConversion != false
        {
            if UserInSession.shared.isFirstConversion == nil
            {
                UserInSession.shared.isFirstConversion = true
            }
            UserInSession.shared.customerID = userID
            optitrack?.set(userID: userID)
            optiPush?.registrar?.register()
            UserInSession.shared.isFirstConversion = false
        }
    }
    
    /// valide user notification permissions and sends the payload to the message handler
    ///
    /// - Parameters:
    ///   - userInfo: the data payload as sends by the the server
    ///   - completionHandler: an indication to the OS that the data is ready to be presented by the system as a notification
    public func handleRemoteNotificationArrived(userInfo: [AnyHashable : Any],
                                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        guard let optIn = UserInSession.shared.isOptIn,
            optIn == true,
            optiPush != nil
            else
        {
            return
        }
        if let optipush = optiPush
        {
            optipush.handleNotification(userInfo: userInfo,
                                        completionHandler: completionHandler)
        }
        else
        {
            completionHandler(.failed)
        }
    }
    
    func handleUserNotificationResponse(response:UNNotificationResponse)
    {
        if let optipush = optiPush
        {
            optipush.handleUserNotificationResponse(response: response)
        }
        else
        {
            pendingNotificationReposnses.append(response)
        }
    }
    
    /// The starting point of the Optimove SDK
    ///
    /// - Parameter info: Basic client information received on the onboarding process with Optimove
    public func configure(info: OptimoveTenantInfo)
    {
        LogManager.reportToConsole("Start Configure Optimove SDK")
        UserInSession.shared.tenantToken = info.token
        UserInSession.shared.version = info.version
        initializeOptimoveComponents( isClientFirebaseExist: info.hasFirebase)
        LogManager.reportToConsole("finish Optimove configuration")
    }
    
    
    /// Registration request to be updated about the SDK state
    ///
    /// - Parameter stateDelegate: entity that conforms to OptimoveStateDelegate
    public func register(stateDelegate: OptimoveStateDelegate)
    {
        monitor.register(stateDelegate: stateDelegate)
    }
    
    /// Unregistration request to not be updated about the SDK state
    ///
    /// - Parameter stateDelegate: entity that conforms to OptimoveStateDelegate
    public func unregister(stateDelegate:OptimoveStateDelegate)
    {
        monitor.unregister(stateDelegate: stateDelegate)
    }
    
    public func register(responder: DynamicLinkResponder)
    {
        optiPush?.register(dynamicLinkResponder: responder)
    }
    
    public func unregister(responder: DynamicLinkResponder)
    {
        optiPush?.unregister(dynamicLinkResponder: responder)
    }
    
    
    /// Request to subscribe to test campaign topics
    public func subscribeToTestMode()
    {
        if let optipush = optiPush
        {
            optipush.subscribeToTestMode()
        }
    }
    
    /// Request to unsubscribe from test campaign topics
    public func unSubscribeFromTestMode()
    {
        if let optipush = optiPush
        {
            optipush.unsubscribeFromTestMode()
        }
    }
    
    /// Request to handle APNS <-> FCM regisration process
    ///
    /// - Parameter deviceToken: A token that was received in the appDelegate callback
    public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
            optiPush?.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    //MARK: - Private Methods
    
    /// Initialize the SDK components
    ///
    /// - Parameter isClientFirebaseExist: an indication of whether the client has already a firebase framework used in its application
    fileprivate func initializeOptimoveComponents( isClientFirebaseExist: Bool)
    {
        OptimoveComponentsInitializer( isClientFirebaseExist: isClientFirebaseExist,
                                       completionHandler:
            { [weak self]  (errors) in
                if !errors.isEmpty
                {
                    self?.monitor.initializationErrors = errors
                }
                else
                {
                    LogManager.reportSuccessToConsole("Optimove Components Successfully initialized ")
                }
        }).startInitialization()
    }
    
    //MARK: - Protocol Conformance
    public func didStartLoading()
    {
    }
    
    public func didBecomeActive()
    {
        DispatchQueue.main.sync
            {
                self.report(event: SetAdvertisingId())
                { (error) in
                    if error != nil
                    {
                        LogManager.reportFailureToConsole("couldn't report IDFA")
                    }
                }
                
                self.report(event: SetUserAgent(userAgent: evaluateUserAgent()))
                { (error) in
                    if error != nil
                    {
                        LogManager.reportFailureToConsole("couldn't report User Agent")
                    }
                }
                if !pendingNotificationReposnses.isEmpty
                {
                    if let optipush = optiPush
                    {
                        for response in pendingNotificationReposnses
                        {
                            optipush.handleUserNotificationResponse(response: response)
                        }
                        pendingNotificationReposnses.removeAll()
                    }
                }
        }
    }
    
    public func didBecomeInvalid(withErrors errors: [OptimoveError])
    {
        
    }
    
   private func evaluateUserAgent() -> UserAgent
    {
        let webView = UIWebView(frame: .zero)
        return webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? ""
    }
}
