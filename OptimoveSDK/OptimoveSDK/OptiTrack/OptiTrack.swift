//
//  Optitrack.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import OptimovePiwikTracker


protocol TrackProtocol
{
    func report(event: OptimoveEvent,withConfigs config: EventConfig, didComplete: ResultBlock? )
    func set(userID: String)
}

final class OptiTrack
{
    //MARK: - Internal Variables
    var metaData: OptitrackMetaData
    var tracker: PiwikTracker?
    
    
    //MARK: - Constructor
    init?(from json: [String: Any],
          initializationDelegate: ComponentInitializationDelegate)
    {
        Optimove.sharedInstance.logger.debug("Initialize OptiTrack")
        
        
        guard let optitrackMetaData = Parser.parseOptitrackMetadata(from: json)
            else
        {
            Optimove.sharedInstance.logger.debug("Failed to parse optitrack metadata")
            
            
            initializationDelegate.didFailInitialization(of: .optiTrack, rootCause: .optiTrackComponentUnavailable)
            return nil
        }
        self.metaData = optitrackMetaData
        if let url = URL.init(string: metaData.optitrackEndpoint)
        {
            PiwikTracker.configureSharedInstance(withSiteID: String(metaData.siteId), baseURL: url)
            tracker = PiwikTracker.shared
        }
        else
        {
            initializationDelegate.didFailInitialization(of: .optiTrack, rootCause: .emptyData)
            return nil
        }
        Optimove.sharedInstance.logger.debug("OptiTrack initialization succeed")
        
        
    }
    
    //MARK: - Internal Methods
    func storeVisitorId()
    {
        UserInSession.shared.visitorID = PiwikTracker.shared?.visitor.visitorId
    }
}
    extension OptiTrack: TrackProtocol
    {
        func report(notificationEvent: NotificationEvent, withConfigs config: EventConfig)
        {
            report(event: notificationEvent, withConfigs: config)
        }
        
        /// save array of notification events to local storage and return index of first element in the stored arrry
        ///
        /// - Parameter events: events to save
        /// - Returns: index of first element in the stored arrry
        func save(_ events: [NotificationEvent]) -> (index:Int,newSize:Int)
        {
            var startIndex = 0
            Optimove.sharedInstance.notificationEventQueue.sync
            {
                var arr = UserInSession.shared.backupNotificationEvents
                startIndex = arr.count
                events.forEach { (event) in
                    arr.append(event.backupString())
                }
                UserInSession.shared.backupNotificationEvents = arr
            }
            return (startIndex,UserInSession.shared.backupNotificationEvents.count)
        }
        
        func report(event: OptimoveEvent,withConfigs config: EventConfig, didComplete: ResultBlock? = nil)
        {
            guard config.supportedComponents[.optiTrack] == true,
                let tracker = PiwikTracker.shared else
            {
                Optimove.sharedInstance.logger.severe("optiTrack component not supported")
                return
            }
            var dimensionsIDs: [Int] = []
            
            dimensionsIDs.append(self.metaData.eventIdCustomDimensionId)
            tracker.set(dimension: CustomDimension(index: metaData.eventIdCustomDimensionId, value: String(config.id)))
            dimensionsIDs.append(self.metaData.eventNameCustomDimensionId)
            tracker.set(dimension: CustomDimension(index: metaData.eventNameCustomDimensionId, value: event.name))
            
            for (name,value) in event.parameters
            {
                if let optitrackDimensionID = config.params[name]?.optitrackDimensionID
                {
                    dimensionsIDs.append(optitrackDimensionID)
                    tracker.set(dimension: CustomDimension(index: optitrackDimensionID, value: String(describing: value)))
                }
            }
            if event is NotificationEvent
            {
                tracker.notificationTrack(eventWithCategory: self.metaData.eventCategoryName,
                                          action: event.name,
                                          name: nil,
                                          number: nil,
                                          url:nil)
            }
            else {
                tracker.track(eventWithCategory: self.metaData.eventCategoryName,
                              action: event.name,
                              name: nil,
                              number: nil,
                              url:nil)
            }
            for index in dimensionsIDs
            {
                tracker.remove(dimensionAtIndex: index)
            }
            didComplete?()
        }
        
        func setScreenEvent(viewControllersIdetifiers:[String],url: URL?)
        {
            Optimove.sharedInstance.logger.debug("report screen event")
            tracker?.track(view: viewControllersIdetifiers, url: url)
        }
        
        func set(userID: String)
        {
            if isInternetAvailable() {
                Optimove.sharedInstance.logger.debug("report set user id: \(userID)")
                Optimove.sharedInstance.report(event: BeforeSetUserId())
                PiwikTracker.shared?.visitorId = userID
                Optimove.sharedInstance.report(event: AfterSetUserId())
                dispatchNow()
                UserInSession.shared.isSetUserIdSucceed = true
            }
        }
        
        func dispatchNow()
        {
            Optimove.sharedInstance.logger.debug("user asked to dispatch")
            PiwikTracker.shared?.dispatch()
            
        }
}

//MARK: Notification report flow
extension OptiTrack
{
    func criticalReport(event: OptimoveEvent,withConfigs config: EventConfig, didComplete: @escaping ResultBlockWithBool)
    {
        guard config.supportedComponents[.optiTrack] == true,
            let tracker = PiwikTracker.shared else
        {
            Optimove.sharedInstance.logger.severe("optiTrack component not supported")
            return
        }
        var dimensionsIDs: [Int] = []
        
        dimensionsIDs.append(self.metaData.eventIdCustomDimensionId)
        tracker.set(dimension: CustomDimension(index: metaData.eventIdCustomDimensionId, value: String(config.id)))
        dimensionsIDs.append(self.metaData.eventNameCustomDimensionId)
        tracker.set(dimension: CustomDimension(index: metaData.eventNameCustomDimensionId, value: event.name))
        
        for (name,value) in event.parameters
        {
            if let optitrackDimensionID = config.params[name]?.optitrackDimensionID
            {
                dimensionsIDs.append(optitrackDimensionID)
                tracker.set(dimension: CustomDimension(index: optitrackDimensionID, value: String(describing: value)))
            }
        }
        
        tracker.criticalTrack(eventWithCategory: self.metaData.eventCategoryName,
                      action: event.name,
                      name: nil,
                      value: nil,
                      url:nil)
        {
            complete in
            for index in dimensionsIDs
            {
                tracker.remove(dimensionAtIndex: index)
            }
            didComplete(complete)
        }
    }
}
