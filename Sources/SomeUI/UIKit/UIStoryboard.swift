//
//  UIStoryboard.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIStoryboard {
  public convenience init(_ name: String) {
    self.init(name: name, bundle: nil)
  }
  public subscript(name: String) -> UIViewController {
    get {
      return instantiateViewController(withIdentifier: name)
    }
  }
  public func get<T>(_ type: T.Type) -> T {
    return self["\(type)"] as! T
  }
  public static func viewController(_ name: String) -> UIViewController {
    let storyboard = UIStoryboard(name)
    return storyboard[name]
  }
  public static func viewController<T>(_ name: String) -> T {
    let storyboard = UIStoryboard(name)
    return storyboard[name] as! T
  }
}

