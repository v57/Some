#if os(iOS)
//
//  Selector.swift
//  Some
//
//  Created by Димасик on 5/18/18.
//  Copyright © 2018 Димасик. All rights reserved.
//

import Foundation

public class ClosureSelector<Parameter> {
  public let selector: Selector
  private let closure: (Parameter)->()
  
  init(closure: @escaping (Parameter)->()){
    self.selector = #selector(ClosureSelector.target)
    self.closure = closure
  }
  
  @objc func target( param: AnyObject) {
    closure(param as! Parameter)
  }
}


import UIKit
public class EmptyClosureSelector {
  public let selector: Selector
  private let closure: ()->()
  
  init(closure: @escaping ()->()) {
    self.selector = #selector(EmptyClosureSelector.target)
    self.closure = closure
  }
  
  @objc func target() {
    closure()
  }
}

extension UIView {
  private static var handle = 0
  @objc func onTouch(_ action: @escaping ()->()) {
    let closureSelector = EmptyClosureSelector(closure: action)
    objc_setAssociatedObject(self, &UIView.handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: closureSelector.selector))
  }
}
#endif
