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
  public static var pagesInited = 0
  public static var pagesClosed = 0
  public static var pagesDeinited = 0
  public static var pages = WeakArray<SomePage>()
}

extension SomeSettings {
  /// default page settings. chenge it on setup()
  public static var showsNavigationBar = false
  public static var statusBarWhite = false
  public static var showsStatusBar = true
  public static var debugPages = false
}

public var ceo: SomeCeo!
var main: SomeMain?
var _main: SomeMain { main! }
public var screen: SomeScreen!

public let application = UIApplication.shared
public let app = UIApplication.shared.delegate as! SomeApp

open class SomeApp: UIResponder {
  public var saveOnDidEnterBackground = false
  public var saveOnFirstLaunch = false
  public var window: UIWindow?
  
  public var info: SomeAppInfo!
  public var states: SomeAppStates!
  public var notifications: SomeAppNotifications!
  
  open var useMain: Bool { true }
  open var root: UIViewController? { main }
  open var disableOnTesting: Bool { true }
  
  func setDefaultValues() {
    screen = SomeScreen.default()
    info = SomeAppInfo.default()
    states = SomeAppStates.default()
    notifications = SomeAppNotifications.default()
    ceo = SomeCeo.default()
    if useMain {
      main = SomeMain.default()
    }
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
      print()
      return true
    }
    info.open()
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
    main?.pages.reversed().forEach { $0.toBackground() }
    states.toBackground()
    pause()
  }
  
  
  open func applicationDidBecomeActive(_ application: UIApplication) {
    guard Device.isInBackground else { return }
    Device.isInBackground = false
    
    let changed = Device.updateLowPowerMode()
    if changed {
      main?.lowPowerModeChanged()
    }
    
    main?.pages.reversed().forEach { $0.fromBackground() }
    states.fromBackground()
    resume()
  }
  
  open func applicationWillTerminate(_ application: UIApplication) {
    states.quit()
    info.close()
  }
  
  open func applicationWillResignActive(_ application: UIApplication) {
    states.inactive()
  }
  
  open func applicationWillEnterForeground(_ application: UIApplication) {
    
  }
  
  open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return screen.orientations
  }
  
  public func application(_ application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
    _application(application, willChangeStatusBarFrame: newStatusBarFrame)
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
    main?.pages.forEach { $0.memoryWarning() }
  }
}

#endif
