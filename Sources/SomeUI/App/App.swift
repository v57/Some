#if os(iOS)

//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import UserNotifications
import Some

private let saveLocation = "some.db"

public struct SomeDebug {
  
}

extension SomeSettings {
  /// default page settings. chenge it on setup()
  public static var showsNavigationBar = false
  public static var statusBarWhite = false
  public static var showsStatusBar = true
  public static var debugPages = false
}

public var ceo: SomeCeo!
public let application = UIApplication.shared
public let app = UIApplication.shared.delegate as! SomeApp

open class SomeApp: UIResponder {
  public var saveOnDidEnterBackground = false
  public var saveOnFirstLaunch = false
  public var window: UIWindow?
  
  public var states: SomeAppStates!
  public var notifications: SomeAppNotifications!
  
  open var root: UIViewController? { nil }
  open var disableOnTesting: Bool { true }
  
  func setDefaultValues() {
    states = SomeAppStates.default()
    notifications = SomeAppNotifications.default()
    ceo = SomeCeo.default()
  }
  
  open func setup() {
    
  }
  open func launch() {
    
  }
  open func resume() {
    
  }
  open func pause() {
    
  }
  open func requestApns() {
    mainThread {
      UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (requested, error) in
        mainThread {
          if let error = error {
            self.notifications.didFail(error: error)
          } else if requested {
            self.notifications.didRegister()
          }
        }
      }
    }
  }
}

extension SomeApp: UIApplicationDelegate {
  open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    setup()
    setDefaultValues()
    if disableOnTesting && NSClassFromString("XCTestCase") != nil {
      return true
    }
    ceo.start()
    ceo.isLoaded = true
    if let root = root {
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = root
      window?.makeKeyAndVisible()
      UIWindow.main = window!
    }
    if let apns = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
      notifications.didReceive(remote: apns)
    }
    launch()
    return true
  }
  open func applicationDidEnterBackground(_ application: UIApplication) {
    guard !Device.isInBackground else { return }
    Device.isInBackground = true
    states.toBackground()
    pause()
  }
  
  
  open func applicationDidBecomeActive(_ application: UIApplication) {
    guard Device.isInBackground else { return }
    Device.isInBackground = false
    Device.updateLowPowerMode()
    states.fromBackground()
    resume()
  }
  
  open func applicationWillTerminate(_ application: UIApplication) {
    states.quit()
  }
  
  open func applicationWillResignActive(_ application: UIApplication) {
    states.inactive()
  }
  
  open func applicationWillEnterForeground(_ application: UIApplication) {
    
  }
  open func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    false
  }
  open func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    false
  }
  
  open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    .all
  }
  
  @available(iOS, introduced: 8.0, deprecated: 10.0)
  open func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
    notifications.didRegister(settings: notificationSettings)
  }
  
  open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    notifications.didFail(error: error)
  }
  
  open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    notifications.didRegister(deviceToken: deviceToken)
  }
  
  open func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    
  }
  
  open func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
    true
  }
}

#endif
