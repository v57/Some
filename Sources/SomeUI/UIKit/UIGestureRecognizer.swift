//
//  UIGestureRecognizer.swift
//  Some
//
//  Created by Димасик on 3/19/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIGestureRecognizer {
  public func cancel() {
    guard isEnabled else { return }
    isEnabled = false
    isEnabled = true
  }
}
