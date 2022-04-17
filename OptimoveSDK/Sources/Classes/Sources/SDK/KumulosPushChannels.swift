//
//  KumulosPushChannels.swift
//  KumulosSDK
//
//  Created by Andy on 07/02/2017.
//  Copyright © 2017 Kumulos. All rights reserved.
//

import Foundation

public typealias PushChannelSubscriptionSuccessBlock = (()->Void)?
public typealias PushChannelSubscriptionFailureBlock = ((Error?)->Void)?

public class KumulosPushChannelSubscriptionRequest {
    var successBlock:PushChannelSubscriptionSuccessBlock?
    var failureBlock:PushChannelSubscriptionFailureBlock?
    
    @discardableResult open func success(_ success:PushChannelSubscriptionSuccessBlock) -> KumulosPushChannelSubscriptionRequest {
        successBlock = success
        return self
    }
    
    @discardableResult open func failure(_ failure:PushChannelSubscriptionFailureBlock) -> KumulosPushChannelSubscriptionRequest {
        failureBlock = failure
        return self
    }
}

public typealias PushChannelSuccessBlock = (([PushChannel])->Void)?
public typealias PushChannelFailureBlock = ((Error?)->Void)?

public class KumulosPushChannelRequest {
    var successBlock:PushChannelSuccessBlock?
    var failureBlock:PushChannelFailureBlock?
    
    @discardableResult open func success(_ success:PushChannelSuccessBlock) -> KumulosPushChannelRequest {
        successBlock = success
        return self
    }
    
    @discardableResult open func failure(_ failure:PushChannelFailureBlock) -> KumulosPushChannelRequest {
        failureBlock = failure
        return self
    }
}

public class KumulosPushChannels {
   
    fileprivate(set) var sdkInstance: Kumulos
    
    public init(sdkInstance: Kumulos)     {
        self.sdkInstance = sdkInstance;
    }
    
    /**
        Get a list of all push channels that are available for subscription or already subscribed to
        by this installation.
     */
    public func listChannels() -> KumulosPushChannelRequest {
        let request = KumulosPushChannelRequest()
        let encodedIdentifier = KSHttpUtil.urlEncode(KumulosHelper.currentUserIdentifier)
        let path =  "/v1/users/\(encodedIdentifier!)/channels"

        sdkInstance.coreHttpClient.sendRequest(.GET, toPath: path, data: nil, onSuccess: { (response, data) in
            if let successBlock = request.successBlock {
                successBlock?(self.readChannelsFromResponse(jsonResponse: (data as! [[String : AnyObject]])))
            }
        }) { (response, error, data)  in
            if let failureBlock = request.failureBlock {
                failureBlock?(error)
            }
        }

        return request
    }
    
    /**
        Create a push channel for subscribing to, it will not be available via the Kumulos portal
     
        - Parameters:
            - uuid: Unique idenfitifer for the channel
            - subscribe: Subscribe the current installation as part of the creation
            - name: Optional descriptive name for the channel, if provided the channel will be publicly available to all requesting apps
            - meta: Optional custom meta-data to associate with this push channel
     */
    public func createChannel(uuid: String, subscribe: Bool, name: String? = nil, meta: [String:AnyObject]? = nil) -> KumulosPushChannelRequest {
        return doCreateChannel(uuid: uuid, subscribe: subscribe, name: name, showInPortal: false, meta: meta)
    }
    
    /**
        Create a push channel for subscribing to
     
        - Parameters:
            - uuid: Unique idenfitifer for the channel
            - subscribe: Subscribe the current installation as part of the creation
            - name: Descriptive name for the channel, if provided the channel will be publicly available to all requesting apps
            - showInPortal: Should the channel show up in the portal for targeting?
            - meta: Optional custom meta-data to associate with this push channel
     */
    public func createChannel(uuid: String, subscribe: Bool, name: String, showInPortal: Bool, meta: [String:AnyObject]? = nil) -> KumulosPushChannelRequest {
        return doCreateChannel(uuid: uuid, subscribe: subscribe, name: name, showInPortal: showInPortal, meta: meta)
    }
    
    
    private func doCreateChannel(uuid: String, subscribe: Bool, name: String? = nil, showInPortal: Bool, meta: [String:AnyObject]? = nil) -> KumulosPushChannelRequest
    {
        let request = KumulosPushChannelRequest()
        let path =  "/v1/channels"
        
        var parameters = [
            "uuid": uuid,
            "showInPortal": showInPortal
        ] as [String: Any];

        if (name != nil) {
            parameters["name"] = name
        }
        
        if (meta != nil) {
            parameters["meta"] = meta
        }
        
        if (subscribe == true) {
            parameters["userIdentifier"] = Kumulos.currentUserIdentifier
        }

        sdkInstance.coreHttpClient.sendRequest(.POST, toPath: path, data: parameters, onSuccess: { (response, data) in
            if let successBlock = request.successBlock {
                successBlock?([self.getChannelFromPayload(payload: (data as! [String : AnyObject]))])
            }
        }) { (response, error, data) in
            if let failureBlock = request.failureBlock {
                failureBlock?(error)
            }
        }

        return request
    }
    
    private func readChannelsFromResponse(jsonResponse: [[String : AnyObject]]) -> [PushChannel] {
        var channels = [PushChannel]();
        
        for item in jsonResponse {
            channels.append(getChannelFromPayload(payload: item))
        }
        
        return channels
    }
    
    private func getChannelFromPayload(payload: [String:AnyObject]) -> PushChannel {
        let channel = PushChannel()
                
        channel.uuid = payload["uuid"] as! String
        channel.isSubscribed = payload["subscribed"] as! Bool
        
        if let name = payload["name"] as? String {
            channel.name = name
        }
        
        if let meta = payload["meta"] as? Dictionary<String, AnyObject> {
            channel.meta = meta
        }
        
        return channel
    }
    
    /**
        Subscribes the current installation to the push channels specified by their unique identifiers.
     
        Channels that don't exist will be created.
     
        - Parameters
            - uuids: The unique push channel identifiers to subscribe to
     
    */
    public func subscribe(uuids: [String]) -> KumulosPushChannelSubscriptionRequest {
        let parameters = [
            "uuids": uuids
        ];
        
        return makeSubscriptionNetworkCall(.POST, parameters: parameters as [String:AnyObject])
    }
    
    /**
        Unsubscribes the current installation from the push channels specified by their unique identifiers.
     
        - Parameters
            - uuids: The unique push channel identifiers to unsubscribe from
     
    */
    public func unsubscribe(uuids: [String]) -> KumulosPushChannelSubscriptionRequest {
        let parameters = [
            "uuids": uuids
        ];
        
        return makeSubscriptionNetworkCall(.DELETE, parameters: parameters as [String:AnyObject])
    }
    
    /**
        Subscribe the current installation to the given push channels.
     
        Any other existing channel subscriptions will be removed.
     
        - Parameters
            - uuids: The unique push channel identifiers to subscribe to
    */
    public func setSubscriptions(uuids: [String]) -> KumulosPushChannelSubscriptionRequest {
        let parameters = [
            "uuids": uuids
        ];
        
        return makeSubscriptionNetworkCall(.PUT, parameters: parameters as [String:AnyObject]);
    }
    
    /**
        Unsubscribe the existing installation from all push channel subscriptions.
    */
    public func clearSubscriptions() -> KumulosPushChannelSubscriptionRequest
    {
        return makeSubscriptionNetworkCall(.PUT, parameters: [:])
    }

    private func makeSubscriptionNetworkCall(_ method: KSHttpMethod, parameters: [String:AnyObject])
        -> KumulosPushChannelSubscriptionRequest
    {
        let encodedIdentifier = KSHttpUtil.urlEncode(KumulosHelper.currentUserIdentifier)
        let path =  "/v1/users/\(encodedIdentifier!)/channels/subscriptions"
        
        return makeNetworkCall(method, path: path, parameters: parameters)
    }
    
    private func makeNetworkCall(_ method: KSHttpMethod, path: String, parameters: [String : AnyObject]) -> KumulosPushChannelSubscriptionRequest {
        let request = KumulosPushChannelSubscriptionRequest()

        sdkInstance.coreHttpClient.sendRequest(method, toPath: path, data: parameters, onSuccess: { (response, body) in
            if let successBlock = request.successBlock {
                successBlock?()
            }
        }) { (response, error, data) in
            if let failureBlock = request.failureBlock {
                failureBlock?(error)
            }
        }

        return request
    }
}

