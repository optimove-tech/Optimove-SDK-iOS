//  Copyright © 2023 Optimove. All rights reserved.

import Foundation
import GenericJSON

@objcMembers
class ObjcJSON: NSObject {
    private var json: JSON

    // Initializer with JSON
    init(json: JSON) {
        self.json = json
    }

    // Convenience initializer for empty JSON
    override init() {
        self.json = JSON.object([:])
    }

    subscript(key: String) -> ObjcJSON? {
        get {
            return jsonObjectForKey(key)
        }
        set {
            if let adapter = newValue {
                try? setJSONObject(adapter, forKey: key)
            }
        }
    }

    var string: String? {
        get {
            return json.stringValue
        }
        set {
            if let value = newValue {
                json = JSON.string(value)
            }
        }
    }

    var bool: Bool? {
        get {
            return json.boolValue
        }
        set {
            if let value = newValue {
                json = JSON.bool(value)
            }
        }
    }

    var double: Double? {
        get {
            return json.doubleValue
        }
        set {
            if let value = newValue {
                json = JSON.number(value)
            }
        }
    }

    var object: [String: ObjcJSON]? {
        get {
            return json.objectValue?.mapValues { ObjcJSON(json: $0) }
        }
        set {
            if let value = newValue {
                json = JSON.object(value.mapValues { $0.json })
            }
        }
    }

    var array: [ObjcJSON]? {
        get {
            return json.arrayValue?.map { ObjcJSON(json: $0) }
        }
        set {
            if let value = newValue {
                json = JSON.array(value.map { $0.json })
            }
        }
    }

    var isNull: Bool {
        return json.isNull
    }

    // MARK: - Accessor Methods

    // Get String value for a key
    func stringValueForKey(_ key: String) -> String? {
        return json[key]?.stringValue
    }

    // Get Boolean value for a key
    func boolValueForKey(_ key: String) -> Bool {
        return json[key]?.boolValue ?? false
    }

    // Get Double value for a key
    func doubleValueForKey(_ key: String) -> Double {
        return json[key]?.doubleValue ?? 0.0
    }

    // Get JSON object for a key
    func jsonObjectForKey(_ key: String) -> ObjcJSON? {
        guard let subJSON = json[key] else { return nil }
        return ObjcJSON(json: subJSON)
    }

    // MARK: - Mutator Methods

    // Set String value for a key
    func setStringValue(_ value: String, forKey key: String) throws {
        json = try json.merging(with: JSON(
            [key: JSON.string(value)]
        ))
    }

    // Set Boolean value for a key
    func setBoolValue(_ value: Bool, forKey key: String) throws {
        json = try json.merging(with: JSON(
            [key: JSON.bool(value)]
        ))
    }

    // Set Double value for a key
    func setDoubleValue(_ value: Double, forKey key: String) throws {
        json = try json.merging(with: JSON(
            [key: JSON.number(value)]
        ))
    }

    // Set JSON object for a key
    func setJSONObject(_ adapter: ObjcJSON, forKey key: String) throws {
        json = json.merging(with: adapter.toGenericJSON())
    }

    // MARK: - Utility Methods

    // Convert to JSON String
    func jsonString() -> String? {
        return json.debugDescription
    }

    // Convert back to GenericJSON for use in Swift
    func toGenericJSON() -> JSON {
        return json
    }
}
