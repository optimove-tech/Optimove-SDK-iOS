//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// A type that describe a remote command.
///
/// - common: A simple command type.
/// - parameterized: A parametrized command type.
enum OptimoveSdkCommand: Decodable {
    case common(OptimoveSdkCommand.Common)
    case parameterized(OptimoveSdkCommand.Parameterized)
}

extension OptimoveSdkCommand {

    enum CodingKeys: CodingKey {
        case command
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let commonValue = try? container.decode(Common.self, forKey: .command) {
            self = .common(commonValue)
        } else if let argumentsValue = try? container.decode(Parameterized.Category.self, forKey: .command) {
            self = .parameterized(.newNotificationCategory(argumentsValue))
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.command],
                    debugDescription: "Unbale to parse an Optiove SDK command. Unsupported command."
                )
            )
        }
    }
}

extension OptimoveSdkCommand {

    /// A simple remote command type.
    ///
    /// - ping:  TODO: Add documentation
    /// - reregister: TODO: Add documentation
    enum Common: String, Decodable {
        case ping
        case reregister
    }

    /// A parametrized remote command type.
    ///
    /// - newNotificationCategory: A new category.
    enum Parameterized {
        case newNotificationCategory(Category)
    }
}

extension OptimoveSdkCommand.Parameterized {

    // MARK: - UserAction
    /// A type that deserialize a notification category with according actions.
    struct Category: Decodable {
        let categoryIdentifier: String
        let actions: [Action]

        enum CodingKeys: String, CodingKey {
            case categoryIdentifier = "category_identifier"
            case actions
        }
    }

    // MARK: - Action
    /// A type of a deserialized action.
    struct Action: Decodable {
        let identifier: String
        let title: String
        let deeplink: String?

        enum CodingKeys: String, CodingKey {
            case identifier
            case title
            case deeplink
        }
    }
}
