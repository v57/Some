#if os(iOS)
//
//  Notifications.swift
//  Some
//
//  Created by Димасик on 11/14/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit
import Some
import UserNotifications

open class SomeAppNotifications: NSObject {
  public static var `default`: ()->SomeAppNotifications = { SomeAppNotifications() }
  public override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
  }
  
  public var token: Data?
  public var history = [PushNotification]()
  public func request() {}
  open func opened(remote notification: PushNotification) throws {}
  open func registered() {}
  open func registerFailed(error: Error) {}
  open func didRegister() {
    application.registerForRemoteNotifications()
  }
  open func didFail(error: Error) {
    print("push error: \(error)")
    registerFailed(error: error)
  }
  
  open func didRegister(deviceToken: Data) {
    guard token == nil else { return }
    token = deviceToken
    registered()
  }

  open func willPresent(notification: UNNotification) -> UNNotificationPresentationOptions {
    .badge
  }
}

extension SomeAppNotifications: UNUserNotificationCenterDelegate {
  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(willPresent(notification: notification))
  }
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    defer { completionHandler() }
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
    didReceive(remote: response.notification.request.content.userInfo)
  }
}

extension SomeAppNotifications {
  public func loaded() {
    guard let last = history.last else { return }
    try? opened(remote: last)
  }
  @available(iOS, deprecated: 10.0)
  func didRegister(settings: UIUserNotificationSettings) {
    didRegister()
  }
  
  public func didReceive(remote userInfo: [AnyHashable : Any]) {
    let notification = PushNotification(userInfo: userInfo)
    history.append(notification)
    try? opened(remote: notification)
  }
}

public class PushNotification {
  public var userInfo: [AnyHashable: Any]
  public init(userInfo: [AnyHashable: Any]) {
    self.userInfo = userInfo
  }
  public func dictionary() throws -> [String: Any] {
    let value = userInfo["aps"] as? [String: Any]
    return try value.try(throw: PushError.noAps)
  }
  public func data() throws -> DataReader {
    let aps = try dictionary()
    let raw64 = aps["d"] as? String
    let base64: String = try raw64.try(throw: PushError.noData)
    return try DataReader(base64: base64).try(throw: PushError.noData)
  }
}

public enum PushError: Error {
  case noAps, noData
  public var localizedDescription: String {
    switch self {
    case .noAps: return "no aps"
    case .noData: return "no data"
    }
  }
}
#endif
