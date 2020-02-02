//  Copyright © 2019 Optimove. All rights reserved.

final class PageVisitEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = "set_page_visit"
        struct Key {
            static let customURL = "customURL"
            static let pageTitle = "pageTitle"
            static let category = "category"
        }
        struct Value {
            /// Using placeholder value only for Matomo backward compatibility.
            static let customURL = "/"
        }
    }

    let name: String = Constants.name
    let parameters: [String: Any]

    init(title: String?, category: String?) {
        self.parameters = [
            Constants.Key.customURL: Constants.Value.customURL,
            Constants.Key.pageTitle: title,
            Constants.Key.category: category
        ].compactMapValues { $0 }
    }
}
