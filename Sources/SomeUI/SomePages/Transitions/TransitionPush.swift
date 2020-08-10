//
//  Push.swift
//  Some
//
//  Created by Димасик on 11/21/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension PageTransition {
  public static var push: PageTransition {
    return Push()
  }
}

private class Push: PageTransition {
  override func opening() {
    super.opening()
    right.frame.x = screen.width
  }
  override func open() {
    super.open()
    if right.shouldHideLeft {
      left?.frame.w = 0
    }
    right.fullscreen()
  }
  override func closing() {
    super.closing()
    if right.shouldHideLeft {
      left?.frame.w = 0
    }
  }
  override func close() {
    super.close()
    if right.shouldHideLeft {
      left?.fullscreen()
    }
    right.frame.x = screen.width
  }
}
