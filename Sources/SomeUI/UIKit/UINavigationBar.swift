//
//  UINavigationBar.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

public extension UINavigationBar {
  var isBackgroundEnabled: Bool {
    get {
      return !(
        shadowImage != nil && isTranslucent)
    }
    set {
      if newValue {
        setBackgroundImage(nil, for: .default)
        shadowImage = nil
        isTranslucent = false
      } else {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
      }
    }
  }
}
