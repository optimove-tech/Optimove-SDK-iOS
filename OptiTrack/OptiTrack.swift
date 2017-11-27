//
//  Optitrack.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import OptimovePiwikTracker

protocol ConversionProcol
{
    func didConvertToCustomer()
}
protocol TrackProtocol
{
    func report(event: OptimoveEvent,withConfigs config: EventConfig)
    func set(userID: String)
}

final class OptiTrack
{
    //MARK: - Internal Variables
    var metaData: OptitrackMetaData
    let optiTrackQueue: DispatchQueue
    //MARK: - Constructor
    private init(from metaData: OptitrackMetaData)
    {
        self.metaData = metaData
        optiTrackQueue = DispatchQueue.init(label: "event_optitrack",
                                            qos: .userInitiated,
                                            attributes: [],
                                            autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                            target: nil)
    }
    
    //MARK: - Private Methods
    private static func handleVisitorIDStore()
    {
        
        UserInSession.shared.visitorID = PiwikTracker.shared?.visitor.visitorId
    }
    
    private static func updateCustomerID()
    {
        //        PiwikTracker.shared?.visitor.customerId = UserInSession.shared.customerID
    }
    
    //MARK: - Internal Methods
    
    static func newIntsance(from json: [String: Any],
                            initializationDelegate: ComponentInitializationDelegate) -> OptiTrack?
    {
        LogManager.reportToConsole("Initialize OptiTrack")
        guard let optitrackConfig = json[Keys.Configuration.optitrackMetaData.rawValue] as? [String: Any],
            let optitrackMetaData = Parser.parseOptitrackMetadata(from: optitrackConfig),
            let isPermitted = json[Keys.Configuration.enableOptitrack.rawValue] as? Bool
            else
        {
            LogManager.reportFailureToConsole("Failed to parse optitrack metadata")
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .error)
            return nil
        }
        let state = isPermitted == true ? State.Component.active : .activeInternal
        let optitrack = OptiTrack(from: optitrackMetaData)
        
        if let url = URL.init(string: optitrack.metaData.optitrackEndpoint)
        {
            PiwikTracker.configureSharedInstance(withSiteID: String.init(optitrack.metaData.siteId), baseURL: url)
            
            self.handleVisitorIDStore()
            self.updateCustomerID()
            
            initializationDelegate.didFinishInitialization(of: .optiTrack,withState: state)
        }
        LogManager.reportSuccessToConsole("OptiTrack initialization succeed")
        return optitrack
    }
}

extension OptiTrack: TrackProtocol
{
    func report(event: OptimoveEvent,withConfigs config: EventConfig)
    {
        guard config.supportedComponents[.optiTrack] == true,
            let tracker = PiwikTracker.shared else
        {
            LogManager.reportFailureToConsole("optiTrack component not supported")
            return
        }
        
        optiTrackQueue.async { [weak self] in
            
            
            var dimensionsIDs: [Int] = []
            if let strongSelf = self
            {
                dimensionsIDs.append(strongSelf.metaData.eventIdCustomDimensionId)
                tracker.set(value:String(config.id), forIndex: strongSelf.metaData.eventIdCustomDimensionId)
                dimensionsIDs.append(strongSelf.metaData.eventNameCustomDimensionId)
                tracker.set(value: event.name, forIndex:strongSelf.metaData.eventNameCustomDimensionId)
                
                
                for (name,value) in event.paramaeters
                {
                    let optitrackDimensionID = config.params[name]!.optitrackDimensionID
                    
                    dimensionsIDs.append(optitrackDimensionID)
                    
                    tracker.set(value: "\(value)", forIndex: optitrackDimensionID)
                }
                
                tracker.track(eventWithCategory: strongSelf.metaData.eventCategoryName,
                              action: event.name,
                              name: nil,
                              number: nil)
                for index in dimensionsIDs
                {
                    tracker.remove(dimensionAtIndex: index)
                }
            }
        }
    }
    
    func set(userID: String)
    {
        UserInSession.shared.customerID = userID
        Optimove.sharedInstance.report(event: BeforeSetUserId()) { (error) in
            guard error == nil else
            {
                LogManager.reportError(error: error)
                return
            }
            PiwikTracker.shared?.visitorId = userID
            //            PiwikTracker.shared?.visitor.customerId = userID
            Optimove.sharedInstance.report(event: AfterSetUserId(), completionHandler: { (error) in
                guard error == nil else
                {
                    LogManager.reportError(error: error)
                    return
                }
            })
        }
    }
    
}
