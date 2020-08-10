#if os(iOS)
//
//  Zoom.swift
//  Some
//
//  Created by Димасик on 11/21/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension PageTransition {
  public static func zoom(view settings: FromViewSettings) -> PageTransition {
    return Zoom(settings: settings)
  }
}

private class Zoom: PageTransitionFromView {
  var s: CGFloat = 1
  var f: CGRect!
  override var isFromView: Bool { true }
  
  override func animation(type: PageTransition.AnimationType, opening: Bool, _ animations: @escaping () -> (), completion: @escaping () -> ()) {
    //    jellyAnimation2(animations, completion)
    animationSettings(time: 0.3, curve: .easeInOut) {
      animate(animations, completion: completion)
    }
  }
  override func opening() {
    super.opening()
    let left = self.left!
    
    main.mainView.addSubview(left)
    
    let from = view.frameOnScreen
    s = from.size.min/right.frame.size.max
    right.scale(s)
    right.center = from.center
  }
  override public func open() {
    super.open()
    let left = self.left!
    
    right.scale(1)
    right.fullscreen()
    
    let scale = 1/s
    
    let from = view.frameOnScreen
    let center = from.center
    
    left.scale(scale)
    left.frame.origin = Pos(-center.x*scale+screen.center.x,-center.y*scale+screen.center.y)
    
    view.alpha = 0
  }
  override func opened() {
    super.opened()
    let left = self.left!
    view.alpha = 1
    left.scale(1)
  }
  override func closing() {
    super.closing()
    let left = self.left!
    
    main.mainView.addSubview(left)
    
    let from = view.frameOnScreen
    s = from.size.min/right.frame.size.max
    
    right.scale(1)
    right.fullscreen()
    
    let scale = 1/s
    
    f = view.frameOnScreen
    let center = f.center
    
    left.scale(scale)
    left.frame.origin = Pos(-center.x*scale+screen.center.x,-center.y*scale+screen.center.y)
    
    view.alpha = 0
  }
  override func close() {
    super.close()
    let left = self.left!
    
    view.alpha = 1
    left.scale(1)
    left.fullscreen()
    right.scale(s)
    right.center = f.center
  }
  override func closed() {
    super.closed()
    f = nil
  }
}
#endif
