//  Copyright © 2023 Optimove. All rights reserved.

import Foundation
import GenericJSON

extension JSON {
    // Convenience initializer to convert from [String: Any]
    init?(dictionary: [String: Any]) {
        var jsonDict = [String: JSON]()

        for (key, value) in dictionary {
            if let stringValue = value as? String {
                jsonDict[key] = JSON.string(stringValue)
            } else if let intValue = value as? Int {
                jsonDict[key] = JSON.number(Double(intValue))
            } else if let doubleValue = value as? Double {
                jsonDict[key] = JSON.number(doubleValue)
            } else if let boolValue = value as? Bool {
                jsonDict[key] = JSON.bool(boolValue)
            } else if let dictValue = value as? [String: Any] {
                jsonDict[key] = JSON(dictionary: dictValue)
            } else if let arrayValue = value as? [Any] {
                jsonDict[key] = JSON(array: arrayValue)
            } else {
                // For unsupported types, you can either skip or handle them differently
                // Skipping here
                Logger.error("Skipping unsupported type: \(type(of: value))")
                continue
            }
        }

        self = JSON.object(jsonDict)
    }

    // Helper to convert an array
    private init?(array: [Any]) {
        var jsonArray: [JSON] = []

        for value in array {
            if let stringValue = value as? String {
                jsonArray.append(JSON.string(stringValue))
            } else if let intValue = value as? Int {
                jsonArray.append(JSON.number(Double(intValue)))
            } else if let doubleValue = value as? Double {
                jsonArray.append(JSON.number(doubleValue))
            } else if let boolValue = value as? Bool {
                jsonArray.append(JSON.bool(boolValue))
            } else if let dictValue = value as? [String: Any] {
                jsonArray.append(JSON(dictionary: dictValue)!)
            } else if let arrayValue = value as? [Any] {
                jsonArray.append(JSON(array: arrayValue)!)
            } else {
                // Handle unsupported types
                Logger.error("Skipping unsupported type: \(type(of: value))")
                continue
            }
        }

        self = JSON.array(jsonArray)
    }
}
