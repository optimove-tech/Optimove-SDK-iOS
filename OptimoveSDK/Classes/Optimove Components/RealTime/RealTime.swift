

import Foundation

class RealTime: OptimoveComponent
{
    var metaData:RealtimeMetaData!
    let realTimeQueue = DispatchQueue(label: "com.optimove.realtime")
    
    
    
    override func performInitializationOperations() {
        super.performInitializationOperations()
        setFirstTimeVisitIfNeeded()
    }
    
    func setUserId(_ event:SetUserId, withConfig config:OptimoveEventConfig)
    {
        realTimeQueue.async {
            let eventDecorator = OptimoveEventDecorator(event: event, config: config)
            let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken,
                                        cid: event.userId,
                                        visitorId: event.originalVistorId,
                                        eid: "\(config.id)",
                context: eventDecorator.parameters)
            self.deviceStateMonitor.getStatus(of: .internet) { (online) in
                guard online else {
                    OptiLogger.warning("Device is offline, skip realtime event set user id")
                    OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                    OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId = event.originalVistorId
                    
                    return
                }
                let json = JSONEncoder()
                do {
                    let data = try json.encode(rtEvent)
                    OptiLogger.debug("report set user id to realtime with JSON: \(String(data:data,encoding:.utf8)!)")
                    NetworkManager.post(toUrl: URL(string:Optimove.sharedInstance.realTime.metaData.realtimeGateway+"reportEvent")!, json: data) { (data, error) in
                        if error != nil {
                            OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                            OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId = event.originalVistorId
                        } else {
                            OptimoveUserDefaults.shared.realtimeSetUserIdFailed = false
                            OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId = nil
                            OptiLogger.debug("real time set user id status:\(String(describing: String(data:data!,encoding:.utf8)!))")
                        }
                    }
                } catch {
                    OptiLogger.error("could not encode realtime set user id request")
                    return
                }
            }
        }
    }
    
    func setEmail(_ event:SetEmailEvent,withConfig config:OptimoveEventConfig)
    {
        realTimeQueue.async {
            let eventDecorator = OptimoveEventDecorator(event: event, config: config)
            let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken,
                                        cid: CustomerID,
                                        visitorId: VisitorID,
                                        eid: "\(config.id)",
                context: eventDecorator.parameters)
            self.deviceStateMonitor.getStatus(of: .internet) { (online) in
                guard online else {
                    OptiLogger.warning("Device is offline, skip realtime event set user id")
                    OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
                    OptimoveUserDefaults.shared.realtimeFailedEmail = event.email
                    return
                }
                let json = JSONEncoder()
                do {
                    let data = try json.encode(rtEvent)
                    OptiLogger.debug("report set email to realtime with JSON: \(String(data:data,encoding:.utf8)!)")
                    NetworkManager.post(toUrl: URL(string:Optimove.sharedInstance.realTime.metaData.realtimeGateway+"reportEvent")!, json: data) { (data, error) in
                        if error != nil {
                            OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
                            OptimoveUserDefaults.shared.realtimeFailedEmail = event.email
                        } else {
                            OptimoveUserDefaults.shared.realtimeSetEmailFailed = false
                            OptimoveUserDefaults.shared.realtimeFailedEmail = nil
                            OptiLogger.debug("real time set user id status:\(String(describing: String(data:data!,encoding:.utf8)!))")
                        }
                    }
                } catch {
                    OptiLogger.error("could not encode realtime set user id request")
                    return
                }
            }
        }
    }
    
    func report(event: OptimoveEvent,withConfigs config: OptimoveEventConfig)
    {
        //Try Set user id and set email anyway
        if OptimoveUserDefaults.shared.realtimeSetUserIdFailed &&  OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId != nil {
            let setUserId = SetUserId(originalVistorId: OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId!, userId: CustomerID!, updateVisitorId: VisitorID)
            if let config = Optimove.sharedInstance.eventWarehouse?.getConfig(ofEvent: setUserId) {
                self.setUserId(setUserId,withConfig: config)
            }
        }
        if OptimoveUserDefaults.shared.realtimeSetEmailFailed &&  OptimoveUserDefaults.shared.realtimeFailedEmail != nil {
            let setEmail = SetEmailEvent(email: OptimoveUserDefaults.shared.realtimeFailedEmail!)
            if let config = Optimove.sharedInstance.eventWarehouse?.getConfig(ofEvent: setEmail) {
                self.setEmail(setEmail, withConfig: config)
            }
        }
        
        guard isEnable else {
            OptiLogger.debug("Attempt to report event \(event.name) when Realtime was not enabled. Maybe check the configurations?")
            return
        }
        
        realTimeQueue.async {
            let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken, cid: OptimoveUserDefaults.shared.customerID, visitorId: VisitorID, eid: String(config.id), context: event.parameters)
            
            self.deviceStateMonitor.getStatus(of: .internet) { (online) in
                guard online else {
                    OptiLogger.warning("Device is offline, skip realtime event reporting \(event.name)")
                    return
                }
                let json = JSONEncoder()
                do {
                    let data = try json.encode(rtEvent)
                    OptiLogger.debug("report event to realtime with JSON: \(String(data:data,encoding:.utf8)!)")
                    NetworkManager.post(toUrl: URL(string:Optimove.sharedInstance.realTime.metaData.realtimeGateway+"reportEvent")!, json: data) { (response, error) in
                        guard error == nil else {
                            OptiLogger.error("request to realtime failed: \(error.debugDescription)")
                            return
                        }
                        OptiLogger.debug("real time report status:\(String(describing: String(data:response!,encoding:.utf8)!))")
                    }
                } catch {
                    OptiLogger.error("could not encode realtime set user id request")
                    return
                }
            }
        }
    }
    private func setFirstTimeVisitIfNeeded() {
        if OptimoveUserDefaults.shared.firstVisitTimestamp == 0  {
            OptimoveUserDefaults.shared.firstVisitTimestamp = Int(Date().timeIntervalSince1970) //Realtime server asked to get it in seconds
        }
    }
}
