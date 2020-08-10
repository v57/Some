#if os(iOS)
//
//  UIAlertController.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIAlertController {
  public class func destructive(title: String?, message: String?, button: String, action: @escaping ()->()) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let destroy = UIAlertAction(title: button, style: .destructive) { _ in
      action()
    }
    alert.addAction(destroy)
    alert.addCancel()
    return alert
  }
  public static func alert() -> UIAlertController {
    UIAlertController(title: nil, message: nil, preferredStyle: .alert)
  }
  public static func actionSheet() -> UIAlertController {
    UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
  }
  public func addCancel() {
    let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    addAction(action)
  }
  public func title(_ string: String) -> Self {
    self.title = string
    return self
  }
  public func description(_ string: String) -> Self {
    self.message = string
    return self
  }
  public func cancel() -> Self {
    button("Cancel", .cancel)
  }
  public func button(_ title: String, _ style: UIAlertAction.Style = .default) -> Self {
    addAction(UIAlertAction(title: title, style: style, handler: nil))
    return self
  }
  public func button(_ title: String, _ style: UIAlertAction.Style = .default, _ action: @escaping ()->()) -> Self {
    addAction(UIAlertAction(title: title, style: style) { _ in action() })
    return self
  }
  public func add(_ title: String, action: (()->())? = nil) {
    var handler: ((UIAlertAction) -> Void)?
    if let action = action {
      handler = { _ in
        action()
      }
    }
    let action = UIAlertAction(title: title, style: .default, handler: handler)
    addAction(action)
  }
  public func addDestructive(_ title: String, action: (()->())? = nil) {
    var handler: ((UIAlertAction) -> Void)?
    if let action = action {
      handler = { _ in
        action()
      }
    }
    let action = UIAlertAction(title: title, style: .destructive, handler: handler)
    addAction(action)
  }
}
#endif
