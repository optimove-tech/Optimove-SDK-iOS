//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

/// A pending analytic metric to be sent to the server
struct PendingAnalyticMetric: Codable, Equatable {
    /// The analytic id
    let id: String
    /// The analytic event type
    let eventType: OptimobileEvent
    /// The analytic event properties's data
    let data: Data?
    /// The analytic event timestamp on the device. In seconds
    let timestamp: Int64

    var properties: [String: Any]? {
        guard let data = data else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }

    init(
        id: String,
        eventType: OptimobileEvent,
        properties: [String: Any]? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970))
    {
        self.id = id
        self.eventType = eventType
        if let properties = properties {
            self.data = try? JSONSerialization.data(withJSONObject: properties, options: [])
        } else {
            self.data = nil
        }
        self.timestamp = timestamp
    }
}

protocol PendingAnalytics {
    func add(metric: PendingAnalyticMetric) throws
    func readAll() throws -> [PendingAnalyticMetric]
    func remove(id: String) throws
    func removeAll() throws
}

final class PendingAnalyticsImpl {
    let storage: KeyValPersistent.Type

    init(storage: KeyValPersistent.Type) {
        self.storage = storage
    }

    lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension PendingAnalyticsImpl: PendingAnalytics {
    func add(metric: PendingAnalyticMetric) throws {
        let pendingMetrics = try readAll()
        if pendingMetrics.contains(where: { $0.id == metric.id }) {
            return
        }
        let data = try encoder.encode(pendingMetrics + [metric])
        storage.set(data, forKey: OptimobileUserDefaultsKey.PENDING_ANALYTICS.rawValue)
    }

    func readAll() throws -> [PendingAnalyticMetric] {
        guard let data = storage.object(forKey: OptimobileUserDefaultsKey.PENDING_ANALYTICS.rawValue) as? Data else {
            return []
        }
        return try decoder.decode([PendingAnalyticMetric].self, from: data)
    }

    func remove(id: String) throws {
        var pendingMetrics = try readAll()
        if let i = pendingMetrics.firstIndex(where: { $0.id == id }) {
            pendingMetrics.remove(at: i)
            let data = try encoder.encode(pendingMetrics)
            storage.set(data, forKey: OptimobileUserDefaultsKey.PENDING_ANALYTICS.rawValue)
        }
    }

    func removeAll() throws {
        storage.removeObject(forKey: OptimobileUserDefaultsKey.PENDING_ANALYTICS.rawValue)
    }
}
