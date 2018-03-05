//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications
import AdSupport
import XCGLogger

/**
 The entry point of Optimove SDK.
 Initialize and configure Optimove using Optimove.sharedOptimove.configure.
 */
@objc public final class Optimove:NSObject
{
    public var optimoveStateDelegateID: Int = -1
    
    //MARK: - Attributes
    var optiPush        : Optipush?
    var optiTrack       : OptiTrack?
    var monitor         : MonitorOptimoveState
    var eventValidator  : OptimoveEventValidator?
    var notificationHandler: OptimoveNotificationHandler
    let evetReportingQueue: DispatchQueue
    let notificationEventQueue: DispatchQueue
    
    public let logger: XCGLogger
    
    let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0]
    }()
    
    @objc public static let sharedInstance = Optimove()
    
    //MARK: - Initializers
    
    fileprivate func initializeLogger() {
        
        func manuallyManageLog(_ logUrl:URL) {
            var fileSize:UInt64
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: logUrl.path)
                fileSize = attr[FileAttributeKey.size] as? UInt64 ?? 0
            }
            catch {
                fileSize = 0
            }
            if fileSize > 3000*1024
            {
                _ = try? FileManager.default.removeItem(at: logUrl)
            }
        }
        
        let logsUrl: URL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent("Logs")
        
        // Create a file log destination
        if !FileManager.default.fileExists(atPath: logsUrl.path)
        {
            do {
                try FileManager.default.createDirectory(at: logsUrl, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                return
            }
        }
        let logUrl: URL = logsUrl.appendingPathComponent("Optimove_logger.txt")
        manuallyManageLog(logUrl)
        
        
        let fileDestination = FileDestination(owner: logger, writeToFile: logUrl, identifier: "advancedLogger.fileDestination", shouldAppend: true, appendMarker: "-- Relauched App --")
        // Optionally set some configuration options
        fileDestination.outputLevel = .debug
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = true
        fileDestination.showThreadName = true
        fileDestination.showLevel = true
        fileDestination.showFileName = true
        fileDestination.showLineNumber = true
        fileDestination.showDate = true
        
        fileDestination.logQueue = XCGLogger.logQueue
        
        // Add the destination to the logger
        logger.add(destination: fileDestination)
        
        
        
        
        
        let  autoRotatingFileDestination = AutoRotatingFileDestination(owner: nil,
                                                                       writeToFile: logUrl,
                                                                       identifier: "advancedLogger.fileDestination",
                                                                       shouldAppend: true,
                                                                       appendMarker: "**********************************",
                                                                       attributes: [:],
                                                                       maxFileSize: 1024 * 5,
                                                                       maxTimeInterval: 600,
                                                                       archiveSuffixDateFormatter: nil)
        
        autoRotatingFileDestination.outputLevel = .verbose
        autoRotatingFileDestination.showLogIdentifier = false
        autoRotatingFileDestination.showFunctionName = true
        autoRotatingFileDestination.showThreadName = true
        autoRotatingFileDestination.showLevel = true
        autoRotatingFileDestination.showFileName = true
        autoRotatingFileDestination.showLineNumber = true
        autoRotatingFileDestination.showDate = true
        autoRotatingFileDestination.targetMaxLogFiles = 1
        autoRotatingFileDestination.logQueue = DispatchQueue.global(qos: .background)
        
        let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
        ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
        ansiColorLogFormatter.colorize(level: .debug, with: .black)
        ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
        ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
        ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
        ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
        autoRotatingFileDestination.formatters = [ansiColorLogFormatter]
        
        // Add the destination to the logger
//        logger.add(destination: autoRotatingFileDestination)
        
        // Add basic app info, version info etc, to the start of the logs
        logger.logAppDetails()
    }
    
    private override init()
    {
        logger = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
        
        
        
        monitor = MonitorOptimoveState()
        notificationHandler = OptimoveNotificationHandler()
        evetReportingQueue = DispatchQueue(label: "event_optitrack",
                                           qos: .userInitiated,
                                           attributes: [],
                                           autoreleaseFrequency: .inherit,
                                           target: nil)
        notificationEventQueue = DispatchQueue(label: "notificationQueue",
                                               qos: .userInitiated,
                                               attributes: [],
                                               autoreleaseFrequency: .inherit,
                                               target: nil)
    }
    
    /// The starting point of the Optimove SDK
    ///
    /// - Parameter info: Basic client information received on the onboarding process with Optimove
    @objc public func configure(info: OptimoveTenantInfo)
    {
        initializeLogger()
        logger.error("Start Configure Optimove SDK")
        monitor.register(stateDelegate: self)
        UserInSession.shared.tenantToken = info.token
        UserInSession.shared.version = info.version
        UserInSession.shared.configurationEndPoint = info.url
        UserInSession.shared.userHasFirebase = info.hasFirebase
        OptimoveComponentsInitializer(isClientFirebaseExist: info.hasFirebase).startFromServer()
        observeEnterToBackgroundMode()
    }
    
    //MARK: - Internal API
    func reportSync(event:OptimoveEvent, completionHandler: ResultBlockWithError? = nil)
    {
        evetReportingQueue.sync
            {
                self.report(event:event, completionHandler:completionHandler)
        }
    }
    
    func report(event:OptimoveEvent, completionHandler: ResultBlockWithError? = nil)
    {
        guard let eventValidator = self.eventValidator else
        {
            if completionHandler != nil
            {
                completionHandler!(.error)
            }
            return
        }
        eventValidator.validate(event: event)
        { (error) in
            if error == nil
            {
                guard let eventConfig = eventValidator.eventsConfigs[event.name] else { return }
                    self.optiTrack?.report(event: event,withConfigs: eventConfig)
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
   
    
    /// validate the state of the sdk and if available internally sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be nil.
    func internalReport(event:OptimoveEvent, completionHandler: ResultBlockWithError? = nil)
    {
        guard  monitor.isComponentInternallyAvailable(.optiTrack) else
        {
            completionHandler?(OptimoveError.noPermissions)
            return
        }
        self.handleReport(event: event,completionHandler: completionHandler)
    }
    
    
    @objc private func trySendNotificationEvents()
    {
        let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        if UIApplication.shared.backgroundTimeRemaining < 6
        {
            // piwik timeout is 5 sec. not enough time. don't ev en try.
            UIApplication.shared.endBackgroundTask(taskId)
            return
        }
        let array = UserInSession.shared.backupNotificationEvents
        if array.isEmpty
        {
            UIApplication.shared.endBackgroundTask(taskId)
            return
        }
        
        self.logger.error("Enter background task with \(array.count) notification events in queue")
        self.logger.error("time remains to background task: \(UIApplication.shared.backgroundTimeRemaining)")
        
        guard let optiTrack = self.optiTrack,
            let tracker = optiTrack.tracker else { return }
        clearStoredNotificationEvents(arraySize: array.count)
        
        var events = [NotificationEvent]()
        for str in array
        {
            if let event = NotificationEvent.newInstance(from: str)
            {
                self.logger.error("append \(event.backupString()) to array of notifications")
                events.append(event)
            }
        }
        
        var counter = events.count
        
        for e in events
        {
            self.reportSync(event: e)
            { _ in // events are assumed to always be valid (ignore error)
                counter -= 1 // callback is executed on main thread, therefor race condition is not a concern
                if counter == 0
                {
                    tracker.dispathNow { success in
                        guard !success else {return}
                        _ = optiTrack.save(events)
                        UIApplication.shared.endBackgroundTask(taskId)
                    }
                }
            }
        }
    }
    
    func clearStoredNotificationEvent(at index:Int, withOldSize oldSize:Int)
    {
        notificationEventQueue.sync
        {
            let currSize = UserInSession.shared.backupNotificationEvents.count
            var diff = 0
            if currSize < oldSize
            {
                diff = oldSize - currSize
            }
            let delIndex = index - diff
            logger.debug("old size: \(oldSize), current size: \(currSize)")
            logger.debug("remove event in index: \(delIndex) from local notification array")
            UserInSession.shared.backupNotificationEvents.remove(at: delIndex)
        }
    }
    
    private func clearStoredNotificationEvents(arraySize: Int)
    {
        notificationEventQueue.sync
        {
            logger.debug("notification array size: \(arraySize)")
            var currentArr = UserInSession.shared.backupNotificationEvents
            logger.debug("current array size: \(currentArr.count)")
            if currentArr.count == arraySize
            {
                UserInSession.shared.backupNotificationEvents = []
            }
            else
            {
                let diff = currentArr.count - arraySize
                var newEvents = [String]()
                for _ in 0..<diff {
                    newEvents.append(currentArr.removeLast())
                }
                UserInSession.shared.backupNotificationEvents = newEvents
            }
        }
    }
    
    //MARK: - Deep Link
   
    var deepLinkResponders = [OptimoveDeepLinkResponder]()
    
    var deepLinkComponents: OptimoveDeepLinkComponents?
    {
        didSet
        {
            guard  let dlc = deepLinkComponents else
            {
                return
            }
            for responder in deepLinkResponders
            {
                responder.didReceive(deepLinkComponent: dlc)
            }
        }
    }
    
    // MARK: - Public API
    
    @objc public func register(deepLinkResponder responder : OptimoveDeepLinkResponder)
    {
        if let dlc = self.deepLinkComponents
        {
            responder.didReceive(deepLinkComponent: dlc)
        }
        else
        {
            deepLinkResponders.append(responder)
        }
    }
    
    @objc public func unregister(deepLinkResponder responder : OptimoveDeepLinkResponder)
    {
        if let index = self.deepLinkResponders.index(of: responder)
        {
            deepLinkResponders.remove(at: index)
        }
    }
    
    @objc public func setScreenEvent(viewControllersIdetifiers:[String],url: URL?)
    {
        guard monitor.isComponentPubliclyAvailable(.optiTrack) else {return}
        optiTrack?.setScreenEvent(viewControllersIdetifiers: viewControllersIdetifiers, url: url)
    }
    
    /// validate the permissions of the client to use optitrack component and if permit sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be nil.
    @objc (reportEventWithEvent: completionHandler:)
    public func objc_reportEvent(event:OptimoveEvent, completionHandler: ((OptimoveError) -> Void)? = nil)
    {
        report(event: event) { (error) in
            completionHandler?(error ?? OptimoveError.noError)
        }
    }
    
     public func reportEvent(event:OptimoveEvent, completionHandler: ((OptimoveError?) -> Void)? = nil)
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
    @objc public func set(userID: String)
    {
        guard !userID.isEmpty, !userID.contains("undefine"), !(userID == "null") else {return}
        let userId = userID.trimmingCharacters(in: .whitespaces)
        if UserInSession.shared.isFirstConversion != false
        {
            if UserInSession.shared.isFirstConversion == nil
            {
                UserInSession.shared.isFirstConversion = true
            }
            if UserInSession.shared.customerID == nil
            {
                UserInSession.shared.isRegistrationSuccess = false
                UserInSession.shared.customerID = userId
            }
            reportSetUserIdIfNeeded()
            registerIfNeeded()
            UserInSession.shared.isFirstConversion = false
        }
    }
    
    /// valid user notification permissions and sends the payload to the message handler
    ///
    /// - Parameters:
    ///   - userInfo: the data payload as sends by the the server
    ///   - completionHandler: an indication to the OS that the data is ready to be presented by the system as a notification
   @objc public func handleRemoteNotificationArrived(userInfo: [AnyHashable : Any],
                                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if UIApplication.shared.applicationState == .inactive || UIApplication.shared.applicationState == .background
        {
            logger.error("start local init of optimove: \(Date.init().timeIntervalSince1970)")
            
            OptimoveComponentsInitializer.init(isClientFirebaseExist: UserInSession.shared.userHasFirebase).startFromLocalConfigs()
            logger.error("finish local init of optimove: \(Date.init().timeIntervalSince1970)")
        }
        notificationHandler.handleNotification(userInfo: userInfo,
                                                  completionHandler: completionHandler)
        
        
    }
    
    /// Registration request to be updated about the SDK state
    ///
    /// - Parameter stateDelegate: entity that conforms to OptimoveStateDelegate
    @objc public func register(stateDelegate: OptimoveStateDelegate)
    {
        monitor.register(stateDelegate: stateDelegate)
    }
    
    /// Unregistration request to not be updated about the SDK state
    ///
    /// - Parameter stateDelegate: entity that conforms to OptimoveStateDelegate
    @objc public func unregister(stateDelegate:OptimoveStateDelegate)
    {
        monitor.unregister(stateDelegate: stateDelegate)
    }
    
    
    
    /// Request to subscribe to test campaign topics
   @objc public func subscribeToTestMode()
    {
        if let optipush = optiPush
        {
            optipush.subscribeToTestMode()
        }
    }
    
    /// Request to unsubscribe from test campaign topics
    @objc public func unSubscribeFromTestMode()
    {
        if let optipush = optiPush
        {
            optipush.unsubscribeFromTestMode()
        }
    }
    
    /// Request to handle APNS <-> FCM regisration process
    ///
    /// - Parameter deviceToken: A token that was received in the appDelegate callback
   @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        optiPush?.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    //MARK: - Private Methods
    private func observeEnterToBackgroundMode()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dispatchNow),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)
    }
    
    private func evaluateUserAgent() -> UserAgent
    {
        let webView = UIWebView(frame: .zero)
        return webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? ""
    }
    
    private func registerIfNeeded()
    {
        if monitor.isComponentInternallyAvailable(.optiPush) && UserInSession.shared.fcmToken != nil &&  UserInSession.shared.isRegistrationSuccess == false
        {
            optiPush?.registrar.register()
        }
    }
    
    private func reportSetUserIdIfNeeded()
    {
        if monitor.isComponentInternallyAvailable(.optiTrack) && UserInSession.shared.isSetUserIdSucceed == false
        {
            guard let userID = UserInSession.shared.customerID else {return}
            optiTrack?.set(userID: userID)
        }
    }
    
    
    /// Validate and send the event to Optitrack component
    ///
    /// - Parameters:
    ///   - event: optimove event object
    ///   - completionHandler: A block object to be executed when the report sequence ends. This block has no return value and takes a single Error argument that indicates whether or not the report actually finished before the completion handler was called. This parameter may be NULL.
    private func handleReport(event:OptimoveEvent, completionHandler: ((OptimoveError?) -> Void)? = nil)
    {
        evetReportingQueue.async
            {
                self.report(event:event, completionHandler:completionHandler)
        }
    }
    
    @objc func dispatchNow()
    {
        optiTrack?.dispatchNow()
    }
}

//MARK: - Protocol Conformance
extension Optimove : OptimoveStateDelegate
{
    public func didStartLoading()
    {
    }
    
    public func didBecomeActive()
    {
        handleSDKStartup()
        unregister(stateDelegate: self)
    }
    
    public func didBecomeInvalid(withErrors errors: [Int])
    {
        handleSDKStartup()
        unregister(stateDelegate: self)
    }
    
    private func handleSDKStartup()
    {
        if monitor.isComponentInternallyAvailable(Component.optiTrack)
        {
            optiTrack?.storeVisitorId()
            trySendNotificationEvents()
            
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled
            {
                Optimove.sharedInstance.logger.error("report IDFA")
                self.internalReport(event: SetAdvertisingId())
            }
            
            Optimove.sharedInstance.logger.error("report User Agent")
            self.internalReport(event: SetUserAgent(userAgent: evaluateUserAgent()))
            
            reportSetUserIdIfNeeded()
            registerIfNeeded()
        }
        if monitor.isComponentInternallyAvailable(Component.optiPush)
        {
            optiPush?.enableNotifications()
            optiPush?.registrar.retryFailedOperationsIfExist()
        }
    }
}
//MARK: Notification reporting flow
extension Optimove
{
    func criticalReportSync(event:OptimoveEvent, completionHandler: @escaping ResultBlockWithBool)
    {
        evetReportingQueue.sync
            {
                self.criticalReport(event:event, completionHandler:completionHandler)
        }
    }
    
    private func criticalReport(event:OptimoveEvent, completionHandler: @escaping ResultBlockWithBool)
    {
        guard let eventValidator = self.eventValidator else
        {
            completionHandler(false)
            return
        }
        eventValidator.validate(event: event)
        { (error) in
            if error == nil
            {
                guard let eventConfig = eventValidator.eventsConfigs[event.name] else { return }
                self.optiTrack?.criticalReport(event: event,withConfigs: eventConfig)
                { success  in
                    completionHandler(success)
                }
            }
            else
            {
                //Validation error, no need for retry
                completionHandler(true)
            }
        }
        
    }
    
}

