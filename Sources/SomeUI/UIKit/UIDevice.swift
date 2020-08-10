#if os(iOS)
//
//  UIDevice.swift
//  Some
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit
import Some

public extension UIDevice {
  /// - Todo: Save id in shared or app directory
  /// - Note: I think its nullable and user can disable sharing its device id to developers.
  /// - Returns: id as Data. Also returns random id if identifierForVendor is nil
  var id: Data {
    if var id = identifierForVendor?.uuid {
      return Data(bytes: raw(&id), count: 16)
    } else {
      return .random(16)
    }
  }
}
public extension UIApplication {
  static var version: String {
    do {
      return try AnyReader(Bundle.main.infoDictionary)
        .at("CFBundleShortVersionString").string()
    } catch {
      return "Unknown"
    }
  }
  static var build: String {
    do {
      return try AnyReader(Bundle.main.infoDictionary)
        .at("CFBundleVersion").string()
    } catch {
      return "Unknown"
    }
  }
}
#endif
