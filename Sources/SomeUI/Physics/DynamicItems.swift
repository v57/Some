#if canImport(UIKit)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 8/16/20.
//

import UIKit

class ViewDynamicItem: NSObject, UIDynamicItem {
  unowned var view: UIView
  init(_ view: UIView) {
    self.view = view
  }
  
  var center: CGPoint {
    get { view.center }
    set { view.center = newValue }
  }

  var bounds: CGRect { view.bounds }

  var transform: CGAffineTransform {
    get { view.transform }
    set { view.transform = newValue }
  }
  class LayerBounds: ViewDynamicItem {
    override var center: CGPoint {
      get { view.layer.bounds.center }
      set { view.layer.bounds.center = newValue }
    }
    override var bounds: CGRect { view.layer.bounds }
  }
}

#endif
