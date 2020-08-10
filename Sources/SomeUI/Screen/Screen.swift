//
//  Screen.swift
//  Some
//
//  Created by Димасик on 11/2/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

public class SomeScreen {
  public static var `default`: ()->SomeScreen = { SomeScreen() }
  
  public private(set) var frame: CGRect = UIScreen.main.bounds
  public private(set) var center: CGPoint = UIScreen.main.bounds.center
  public private(set) var statusBarHeight: CGFloat = 0
  public private(set) var safeArea: UIEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
  public private(set) var customSafeArea: UIEdgeInsets = .zero
  public let cornerRadius: CGFloat = device.cornerRadius
  public var orientations: UIInterfaceOrientationMask = .all
  public var isLeftToRight: Bool {
    return UIApplication.shared.userInterfaceLayoutDirection != .rightToLeft
  }
  
  public var statusBarY: CGFloat = 0 {
    didSet {
      let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as! UIWindow;
      var f = statusBarWindow.frame;
      f.y = max(statusBarY,0)
      statusBarWindow.frame = f
    }
  }
  public var forceTouchAvailable: Bool {
    return UIWindow.main.traitCollection.forceTouchCapability == .available
  }
  
  var isLocked = false
  var shouldUpdate = false
  
  init() {
    updateSafeArea()
  }
  init(viewController: UIViewController) {
    updateSafeArea()
  }
  
  func sendUpdates() {
    shouldUpdate = true
    guard !isLocked else { return }
    shouldUpdate = false
    main?.resolutionChanged()
  }
  
  func lock(execute: ()->()) {
    isLocked = true
    execute()
    isLocked = false
    guard shouldUpdate else { return }
    sendUpdates()
  }
  
  func updateSafeArea() {
    if device == .iphoneX {
      if resolution.width > resolution.height {
        safeArea = UIEdgeInsets(top: 20.0, left: 44.0, bottom: 21.0, right: 44.0)
      } else {
        safeArea = UIEdgeInsets(top: 44.0, left: 0.0, bottom: 34.0, right: 0.0)
      }
    } else {
      safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
  }
}

extension SomeScreen {
  public var dframe: DFrame { return { [unowned(unsafe) self] in self.frame } }
  public var dframeSafe: DFrame { return { self.safeFrame } }
  public var resolution: CGSize {
    get { frame.size }
    set {
      frame.size = newValue
      center = newValue.center
      Device.updateType()
      updateSafeArea()
      sendUpdates()
    }
  }
  public var width: CGFloat { resolution.width }
  public var height: CGFloat { resolution.height }
  public var retina: CGFloat { UIScreen.main.scale }
  public var pixel: CGFloat { 1 / UIScreen.main.scale }
  public var isLandscape: Bool { width > height }
  public var brigtness: CGFloat { UIScreen.main.brightness }
  public var orientation: UIInterfaceOrientation {
    get { UIApplication.shared.statusBarOrientation }
    set { UIDevice.current.setValue(newValue.rawValue, forKey: "orientation") }
  }
  
  public var top: CGFloat {
    get { safeArea.top + customSafeArea.top }
    set {
      customSafeArea.top = newValue
      sendUpdates()
    }
  }
  public var bottom: CGFloat {
    get { height - bottomInsets }
    set {
      customSafeArea.bottom = newValue
      sendUpdates()
    }
  }
  public var bottomInsets: CGFloat {
    return safeArea.bottom + customSafeArea.bottom
  }
  public var topInsets: CGFloat {
    return safeArea.top + customSafeArea.top
  }
  public var safeWidth: CGFloat {
    return right - left
  }
  public var left: CGFloat {
    get { safeArea.left + customSafeArea.left }
    set {
      customSafeArea.left = newValue
      sendUpdates()
    }
  }
  public var right: CGFloat {
    get { width - (safeArea.right + customSafeArea.right) }
    set {
      customSafeArea.right = newValue
      sendUpdates()
    }
  }
  public var rightInsets: CGFloat {
    return safeArea.right + customSafeArea.right
  }
  public var safeFrame: CGRect {
    return CGRect(left,top,right,bottom-topInsets)
  }
}

extension UIInterfaceOrientation {
  public static var current: UIInterfaceOrientation {
    return UIApplication.shared.statusBarOrientation
  }
}
