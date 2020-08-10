//
//  Fade.swift
//  Some
//
//  Created by Димасик on 11/21/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension PageTransition {
  public static var fade: PageTransition {
    return Fade()
  }
}

private class Fade: PageTransition {
  override func opening() {
    super.opening()
    right.alpha = 0
  }
  override public func open() {
    super.open()
    if right.shouldHideLeft {
      left?.alpha = 0
    }
    right.alpha = 1
  }
  override func opened() {
    super.opened()
    left?.alpha = 1
  }
  override func closing() {
    super.closing()
    if right.shouldHideLeft {
      left?.alpha = 0
    }
  }
  override func close() {
    super.close()
    if right.shouldHideLeft {
      left?.alpha = 1
    }
    right.alpha = 0
  }
  override func closed() {
    super.closed()
    right.alpha = 1
  }
}
