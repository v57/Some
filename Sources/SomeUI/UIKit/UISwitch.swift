#if os(iOS)
//
//  UISwitch.swift
//  Some
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

private var switchSize: CGSize?
private var handle = 0
public extension UISwitch {
  static let size = UISwitch(frame: .zero).frame.size
  convenience init(pos: Pos, anchor: Anchor, on: Bool) {
    self.init(frame: .zero)
    move(pos,anchor)
    isOn = on
  }
  func on(_ isOn: Bool) -> Self {
    self.isOn = isOn
    return self
  }
  func onTouch(_ action: @escaping (Bool)->()) {
    add(on: .touchUpInside, action: action)
  }
  func add(on controlEvents: UIControl.Event, action: @escaping (Bool)->()) {
    let closureSelector = ClosureSelector<UISwitch>(closure: { view in
      action(view.isOn)
    })
    objc_setAssociatedObject(self, &handle, closureSelector, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    addTarget(closureSelector, action: closureSelector.selector, for: controlEvents)
  }
}
#endif
