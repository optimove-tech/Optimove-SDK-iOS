import Foundation

class RealTime: OptimoveComponent
{
    var metaData:RealtimeMetaData!
    private let realTimeQueue = DispatchQueue(label: "com.optimove.realtime")

    override func performInitializationOperations() {
        super.performInitializationOperations()
        setFirstTimeVisitIfNeeded()
    }

    func reportScreenEvent(customURL: String, pageTitle: String, category: String?)
    {
        let event = OptimoveEventDecorator(event: PageVisitEvent(customURL: customURL, pageTitle: pageTitle, category: category))
        guard let config = Optimove.sharedInstance.eventWarehouse?.getConfig(ofEvent: event) else {
            OptiLogger.error("configurations for event: \(event.name) are missing")
            return
        }
        event.processEventConfig(config)
        self.report(event: event, withConfigs: config)
    }

    func report(event: OptimoveEvent,withConfigs config: OptimoveEventConfig)
    {
        //Verify that failed set_user_id is dispatched before failed set_email and before any custom event
        if event.name == OptimoveKeys.Configuration.setUserId.rawValue {
            self.setUserId(event, withConfig: config)
            return
        }
        if OptimoveUserDefaults.shared.realtimeSetUserIdFailed {
            let setUserId = SetUserId(originalVistorId: InitialVisitorID,
                                      userId: CustomerID!,
                                      updateVisitorId: VisitorID)
            if let config = Optimove.sharedInstance.eventWarehouse?.getConfig(ofEvent: setUserId) {
                self.setUserId(setUserId,withConfig: config)
            }
        }

        if event.name == OptimoveKeys.Configuration.setEmail.rawValue {
            self.setEmail(event, withConfig: config)
            return
        }
        if OptimoveUserDefaults.shared.realtimeSetEmailFailed  {
            let setEmail = SetEmailEvent(email: UserEmail!)
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
    
    private func setUserId(_ event:OptimoveEvent, withConfig config:OptimoveEventConfig)
    {
        realTimeQueue.async {
            let eventDecorator = OptimoveEventDecorator(event: event, config: config)
            let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken,
                                        cid: CustomerID,
                                        visitorId: InitialVisitorID,
                                        eid: "\(config.id)",
                context: eventDecorator.parameters)
            self.deviceStateMonitor.getStatus(of: .internet) { (online) in
                guard online else {
                    OptiLogger.warning("Device is offline, skip realtime event set user id")
                    OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                    return
                }
                let json = JSONEncoder()
                do {
                    let data = try json.encode(rtEvent)
                    OptiLogger.debug("report set user id to realtime with JSON: \(String(data:data,encoding:.utf8)!)")
                    NetworkManager.post(toUrl: URL(string:Optimove.sharedInstance.realTime.metaData.realtimeGateway+"reportEvent")!, json: data) { (data, error) in
                        if error != nil {
                            OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                        } else {
                            OptimoveUserDefaults.shared.realtimeSetUserIdFailed = false
                            OptiLogger.debug("real time set user id status:\(String(describing: String(data:data!,encoding:.utf8)!))")
                        }
                    }
                } catch {
                    OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                    OptiLogger.error("could not encode realtime set user id request")
                    return
                }
            }
        }
    }
    
    private func setEmail(_ event:OptimoveEvent,withConfig config:OptimoveEventConfig)
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
                    OptiLogger.warning("Device is offline, skip realtime event set email")
                    OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
                    return
                }
                let json = JSONEncoder()
                do {
                    let data = try json.encode(rtEvent)
                    OptiLogger.debug("report set email to realtime with JSON: \(String(data:data,encoding:.utf8)!)")
                    NetworkManager.post(toUrl: URL(string:Optimove.sharedInstance.realTime.metaData.realtimeGateway+"reportEvent")!, json: data) { (data, error) in
                        if error != nil {
                            OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
                        } else {
                            OptimoveUserDefaults.shared.realtimeSetEmailFailed = false
                            OptiLogger.debug("real time set email status:\(String(describing: String(data:data!,encoding:.utf8)!))")
                        }
                    }
                } catch {
                    OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
                    OptiLogger.error("could not encode realtime set user id request")
                    return
                }
            }
        }
    }

    private func setFirstTimeVisitIfNeeded()
    {
        if OptimoveUserDefaults.shared.firstVisitTimestamp == 0  {
            OptimoveUserDefaults.shared.firstVisitTimestamp = Int(Date().timeIntervalSince1970) //Realtime server asked to get it in seconds
        }
    }
}
