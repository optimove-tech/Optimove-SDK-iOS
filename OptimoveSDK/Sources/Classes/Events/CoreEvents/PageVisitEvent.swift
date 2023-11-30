//  Copyright © 2019 Optimove. All rights reserved.

final class PageVisitEvent: Event {
    enum Constants {
        static let name = "set_page_visit"
        enum Key {
            static let customURL = "customURL"
            static let pageTitle = "pageTitle"
            static let category = "category"
        }

        enum Value {
            /// Using placeholder value only for Matomo backward compatibility.
            static let customURL = "/"
        }
    }

    init(title: String?, category: String?) {
        super.init(
            name: Constants.name,
            context: [
                Constants.Key.customURL: Constants.Value.customURL,
                Constants.Key.pageTitle: title,
                Constants.Key.category: category,
            ].compactMapValues { $0 }
        )
    }
}
