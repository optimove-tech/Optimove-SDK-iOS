//  Copyright © 2026 Optimove. All rights reserved.

import UIKit

/// Root view controller for SDK-owned windows (in-app, overlay messaging).
/// Stands in for the host app's top view controller as it was when the window
/// was created, answering UIKit with the host's settings instead of defaults.
/// Currently carries over supported orientations only.
final class HostSnapshotViewController: UIViewController {
    private let hostOrientations: UIInterfaceOrientationMask?

    /// - Parameter window: the SDK window this controller will be root of; must not be visible yet.
    init(for window: UIWindow) {
        hostOrientations = HostSnapshotViewController.hostOrientations(for: window)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return hostOrientations ?? super.supportedInterfaceOrientations
    }

    private static func hostOrientations(for window: UIWindow) -> UIInterfaceOrientationMask? {
        var windows = UIApplication.shared.windows
        if #available(iOS 13.0, *), let scene = window.windowScene {
            windows = scene.windows
        }
        
        windows = windows.filter { $0 !== window }

        let hostWindow = windows.first { $0.isKeyWindow }
            ?? windows
            .filter { !$0.isHidden && $0.windowLevel < .alert && $0.rootViewController != nil }
            .max { $0.windowLevel.rawValue < $1.windowLevel.rawValue }

        var top = hostWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top?.supportedInterfaceOrientations
    }
}
