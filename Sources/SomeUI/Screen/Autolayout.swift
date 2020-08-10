//
//  autolayout.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

private var statusBarHeight: CGFloat = 20

extension SomeMain {
  func _viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    let animated = pages.last?.animateScreenTransitions ?? false
    if !animated {
      UIView.setAnimationsEnabled(false)
    }
    coordinator.animate(alongsideTransition: { _ in
      if animated {
        isAnimating = true
      }
      screen.resolution = size
      if animated {
        isAnimating = false
      }
      if !animated {
        UIView.setAnimationsEnabled(true)
      }
      
    }, completion: nil)
  }
  func _resolutionChanged() {
    if #available(iOS 9.0, *) {
      viewIfLoaded?.resolutionChanged()
    } else {
      view.resolutionChanged()
    }
  }
}

extension SomeApp {
  func _application(_ application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
    
    let offset = newStatusBarFrame.h - statusBarHeight
    guard offset != 0 else { return }
    statusBarHeight = newStatusBarFrame.h
    
    var size = screen.resolution
    size.height -= offset
    
    UIView.animate(withDuration: 0.35) {
      screen.resolution = size
    }
  }
}

protocol UIViewResolutionProtocol: class {
  func resolutionChanged()
}

extension UIView: UIViewResolutionProtocol {
  @objc open func resolutionChanged() {
    for view in subviews {
      if let dview = view as? DynamicFrame, let dframe = dview.dframe {
        view.frame = dframe()
      } else if let dview = view as? DynamicPos, let dpos = dview.dpos {
        let (pos,anchor) = dpos()
        view.move(pos,anchor)
      } else if let dview = view as? DynamicCenter, let dcenter = dview.dcenter {
        view.center = dcenter()
      } else if let dview = view as? DynamicFrame2 {
        dview.dynamicLayout?.updateFrame(parent: self, child: view)
      }
      view.resolutionChanged()
    }
  }
}
