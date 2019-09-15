//  Copyright © 2019 James Horan. All rights reserved.

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set the main application UIWindow bounds
        window = UIWindow(frame: UIScreen.main.bounds)

        // Create the main view controller. No need for a UINavigationController
        let viewController = ViewController()

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()

        return true
    }
}
