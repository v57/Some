#if os(iOS)
//
//  Device.swift
//  Some
//
//  Created by Димасик on 11/2/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit
import Some


extension SomeSettings {
  public static var lowPowerMode = LowPowerMode()
  public struct LowPowerMode {
    public var disableAnimations = true
  }
}

public var device = DeviceType(resolution: UIScreen.main.bounds.size)
public class Device {
  public static var isInBackground = false
  public static var lowPowerMode = _lowPowerMode
  public static var isSimulator: Bool {
    return TARGET_OS_SIMULATOR != 0
  }
  
  private static var _lowPowerMode: Bool {
    if #available(iOS 9.0, *) {
      return ProcessInfo.processInfo.isLowPowerModeEnabled
    } else {
      return false
    }
  }
  @discardableResult
  static func updateLowPowerMode() -> Bool {
    guard !isInBackground else { return false }
    let newValue = _lowPowerMode
    guard lowPowerMode != newValue else { return false }
    lowPowerMode = newValue
    return true
  }
  static func updateType() {
    device = DeviceType(resolution: UIScreen.main.bounds.size)
  }
}

extension DeviceType: Comparable {
  public static func <(lhs: DeviceType, rhs: DeviceType) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  public static func <=(lhs: DeviceType, rhs: DeviceType) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  
  public static func >=(lhs: DeviceType, rhs: DeviceType) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }
  
  public static func >(lhs: DeviceType, rhs: DeviceType) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
//  public static func <(lhs: DeviceType, rhs: DeviceType) -> Bool {
//    return lhs.rawValue < rhs.rawValue
//  }
}

public enum DeviceType: Int {
  case iphone4, iphone5, iphone6, iphoneX, iphone6plus, ipad, ipadpro
  init(resolution: CGSize) {
    var size = resolution
    if size.width > size.height {
      size.rotate()
    }
    
    if size <= DeviceType.iphone4.size {
      self = .iphone4
    } else if size <= DeviceType.iphone5.size {
      self = .iphone5
    } else if size <= DeviceType.iphone6.size {
      self = .iphone6
    } else if size <= DeviceType.iphoneX.size {
      self = .iphoneX
    } else if size <= DeviceType.iphone6plus.size {
      self = .iphone6plus
    } else if size <= DeviceType.ipad.size {
      self = .ipad
    } else {
      self = .ipadpro
    }
  }
  var size: CGSize {
    switch self {
    case .iphone4: return CGSize(320,480)
    case .iphone5: return CGSize(320,568)
    case .iphone6: return CGSize(375,667)
    case .iphoneX: return CGSize(375,812)
    case .iphone6plus: return CGSize(414,736)
    case .ipad: return CGSize(768,1024)
    case .ipadpro: return CGSize(1024,1366)
    }
  }
  public var cornerRadius: CGFloat {
    switch self {
    case .iphoneX: return 40
    default: return 0
    }
  }
}
#endif
