//
//  ForceTouchGesture.swift
//  Some
//
//  Created by Димасик on 5/23/18.
//  Copyright © 2018 Димасик. All rights reserved.
//

//import UIKit
import UIKit.UIGestureRecognizerSubclass

public class ForceTouchGestureRecognizer: UILongPressGestureRecognizer {
  public private(set) var previousForce: CGFloat = 0.0
  public private(set) var force: CGFloat = 0.0
  public var haveForce: Bool = false
  
  convenience init() {
    self.init(target: nil, action: nil)
  }
  
  public override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    cancelsTouchesInView = false
  }
  
  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    update(touches)
    super.touchesBegan(touches, with: event)
  }
  
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    update(touches)
    super.touchesMoved(touches, with: event)
  }
  
  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    update(touches)
    super.touchesEnded(touches, with: event)
  }
  
  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    update(touches)
    super.touchesCancelled(touches, with: event)
  }
  
  private func update(_ touches: Set<UITouch>) {
    guard let touch = touches.first else { return }
    previousForce = force
    force = touch.force / touch.maximumPossibleForce
  }
  
  public override func reset() {
    super.reset()
    force = 0.0
  }
}
