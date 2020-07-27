//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import CoreData

final class EventCDv1ToEventCDv2MigrationPolicy: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        if sInstance.entity.name == EventCD.entityName {
            let queueType: String = try cast(sInstance.primitiveValue(forKey: #keyPath(EventCD.type)))
            let data: Data = try cast(sInstance.primitiveValue(forKey: #keyPath(EventCD.data)))
            let sObject = try JSONDecoder().decode(MigrationSource_OptistreamEvent_v1.self, from: data)

            let dObject = OptistreamEvent(
                tenant: sObject.tenant,
                category: sObject.category,
                event: sObject.event,
                origin: sObject.origin,
                customer: sObject.customer,
                visitor: sObject.visitor,
                timestamp: sObject.timestamp,
                context: sObject.context,
                metadata: OptistreamEvent.Metadata(
                    channel: OptistreamEvent.Metadata.Channel(
                        airship: sObject.metadata.channel?.airship
                    ),
                    realtime: sObject.metadata.realtime,
                    firstVisitorDate: sObject.metadata.firstVisitorDate,
                    eventId: sObject.metadata.uuid,
                    validations: []
                )
            )
            let dInstance = try EventCDv2.insert(
                into: manager.destinationContext,
                event: dObject,
                of: try cast(OptistreamQueueType(rawValue: queueType))
            )
            manager.associate(sourceInstance: sInstance, withDestinationInstance: dInstance, for: mapping)
        } else {
            try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        }
    }

}

fileprivate struct MigrationSource_OptistreamEvent_v1: Codable {
    public let tenant: Int
    public let category: String
    public let event: String
    public let origin: String
    public let customer: String?
    public let visitor: String
    public let timestamp: String
    public let context: JSON
    public var metadata: Metadata

    public struct Metadata: Codable, Hashable {

        public struct Channel: Codable, Hashable {

            public let airship: OptimoveAirshipIntegration.Airship?

            public init(airship: OptimoveAirshipIntegration.Airship?) {
                self.airship = airship
            }
        }

        public let channel: Channel?
        public var realtime: Bool
        public var firstVisitorDate: Int64
        public let uuid: String

        public init(
            channel: MigrationSource_OptistreamEvent_v1.Metadata.Channel?,
            realtime: Bool,
            firstVisitorDate: Int64,
            uuid: String
        ) {
            self.channel = channel
            self.realtime = realtime
            self.firstVisitorDate = firstVisitorDate
            self.uuid = uuid
        }

    }

    public init(
        tenant: Int,
        category: String,
        event: String,
        origin: String,
        customer: String?,
        visitor: String,
        timestamp: String,
        context: JSON,
        metadata: Metadata
    ) {
        self.tenant = tenant
        self.category = category
        self.event = event
        self.origin = origin
        self.customer = customer
        self.visitor = visitor
        self.timestamp = timestamp
        self.context = context
        self.metadata = metadata
    }
}

extension MigrationSource_OptistreamEvent_v1: Equatable {

    public static func == (lhs: MigrationSource_OptistreamEvent_v1, rhs: MigrationSource_OptistreamEvent_v1) -> Bool {
        return lhs.metadata.uuid == rhs.metadata.uuid
    }

}

extension MigrationSource_OptistreamEvent_v1: Hashable { }
