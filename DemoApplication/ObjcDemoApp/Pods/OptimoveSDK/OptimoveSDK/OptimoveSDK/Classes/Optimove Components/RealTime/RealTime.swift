import Foundation

class RealTime: OptimoveComponent {
	var metaData: RealtimeMetaData!

	private let realTimeQueue = DispatchQueue(label: "com.optimove.realtime")

	override func performInitializationOperations() {
		super.performInitializationOperations()
		setFirstTimeVisitIfNeeded()
	}

	func reportScreenEvent(customURL: String, pageTitle: String, category: String?) {
		let event = OptimoveEventDecorator(event: PageVisitEvent(customURL: customURL, pageTitle: pageTitle, category: category))
		guard let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) else {
			OptiLoggerMessages.logConfigForEventMissing(eventName: event.name)
			return
		}
		event.processEventConfig(config)
		self.report(eventDecor: event, withConfigs: config)
	}

	func report(eventDecor event: OptimoveEventDecorator, withConfigs config: OptimoveEventConfig) {
		//Verify that failed set_user_id is dispatched before failed set_email and before any custom event
		if event.name == OptimoveKeys.Configuration.setUserId.rawValue {
			self.setUserId(event, withConfig: config)
			return
		}
		if OptimoveUserDefaults.shared.realtimeSetUserIdFailed {
			let setUserId = SetUserId(originalVistorId: InitialVisitorID,
					userId: CustomerID!,
					updateVisitorId: VisitorID)
			if let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: setUserId) {
                let eventDecorator = OptimoveEventDecoratorFactory.getEventDecorator(forEvent: setUserId, withConfig: config)
				self.setUserId(eventDecorator, withConfig: config)
			}
		}

		if event.name == OptimoveKeys.Configuration.setEmail.rawValue {
			self.setEmail(event, withConfig: config)
			return
		}
		if OptimoveUserDefaults.shared.realtimeSetEmailFailed {
			let setEmail = SetEmailEvent(email: UserEmail!)
			if let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: setEmail) {
                let eventDecorator = OptimoveEventDecoratorFactory.getEventDecorator(forEvent: setEmail, withConfig: config)
				self.setEmail(eventDecorator, withConfig: config)
			}
		}

		guard isEnable else {
			OptiLoggerMessages.logRealtimeDisable(eventName: event.name)
			return
		}

		realTimeQueue.async {
			let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken, cid: OptimoveUserDefaults.shared.customerID, visitorId: VisitorID, eid: String(config.id), context: event.parameters)

			self.deviceStateMonitor.getStatus(of: .internet) { (online) in
				guard online else {
					OptiLoggerMessages.logOfflineStatusForrealtime(eventName: event.name)
					return
				}
				let json = JSONEncoder()
				do {
					let data = try json.encode(rtEvent)
					let json = String(decoding: data, as: UTF8.self)
					OptiLoggerMessages.logRealtimeReportEvent(json: json)

					NetworkManager.post(toUrl: URL(string: Optimove.shared.realTime.metaData.realtimeGateway + "reportEvent")!, json: data) { (response, error) in
						guard error == nil else {
							OptiLoggerMessages.logRealtimeRequestFailure(errorDescription: error.debugDescription)
							return
						}
						OptiLoggerMessages.logRealtimeReportStatus(json: String(decoding: response!, as: UTF8.self))
					}
				} catch {
					OptiLoggerMessages.logRealtimeSetUSerIdEncodeFailure()
					return
				}
			}
		}
	}

	private func setUserId(_ event: OptimoveEventDecorator, withConfig config: OptimoveEventConfig) {
		realTimeQueue.async {
			let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken,
					cid: CustomerID,
					visitorId: InitialVisitorID,
					eid: "\(config.id)",
					context: event.parameters)
			self.deviceStateMonitor.getStatus(of: .internet) { (online) in
				guard online else {
					OptiLoggerMessages.logSkipSetUserIdForRealtime()
					OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
					return
				}
				let json = JSONEncoder()
				do {
					let data = try json.encode(rtEvent)
					OptiLoggerMessages.logRealtimeSetUserIdReport(json: String(decoding: data, as: UTF8.self))
					NetworkManager.post(toUrl: URL(string: Optimove.shared.realTime.metaData.realtimeGateway + "reportEvent")!, json: data) { (data, error) in
						if error != nil {
							OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
						} else {
							OptimoveUserDefaults.shared.realtimeSetUserIdFailed = false
							OptiLoggerMessages.logRealtimeSetUserIdStatus(status: String(decoding: data!, as: UTF8.self))
						}
					}
				} catch {
					OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
					OptiLoggerMessages.logRealtimeSetUserIDEncodeFailure()
					return
				}
			}
		}
	}

	private func setEmail(_ event: OptimoveEventDecorator, withConfig config: OptimoveEventConfig) {
		realTimeQueue.async {
			let rtEvent = RealtimeEvent(tid: self.metaData.realtimeToken,
					cid: CustomerID,
					visitorId: VisitorID,
					eid: "\(config.id)",
					context: event.parameters)
			self.deviceStateMonitor.getStatus(of: .internet) { (online) in
				guard online else {
					OptiLoggerMessages.logSkipSetEmailForRealtime()
					OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
					return
				}
				let json = JSONEncoder()
				do {
					let data = try json.encode(rtEvent)
					OptiLoggerMessages.logRealtimeSetEmailReport(json: String(decoding: data, as: UTF8.self))
					NetworkManager.post(toUrl: URL(string: Optimove.shared.realTime.metaData.realtimeGateway + "reportEvent")!, json: data) { (data, error) in
						if error != nil {
							OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
						} else {
							OptimoveUserDefaults.shared.realtimeSetEmailFailed = false
							OptiLoggerMessages.logRealtimeSetEmailStatus(status: String(decoding: data!, as: UTF8.self))
						}
					}
				} catch {
					OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
					OptiLoggerMessages.logRealtimeSetEmailEncodeFailure()
					return
				}
			}
		}
	}

	private func setFirstTimeVisitIfNeeded() {
		if OptimoveUserDefaults.shared.firstVisitTimestamp == 0 {
			OptimoveUserDefaults.shared.firstVisitTimestamp = Int(Date().timeIntervalSince1970) //Realtime server asked to get it in seconds
		}
	}
}
