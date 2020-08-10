#if os(iOS)
//
//  PageOverlay.swift
//  Some
//
//  Created by Димасик on 11/2/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

public class PageOverlay {
  public static var `default`: ()->PageOverlay = { PageOverlay() }
  
  public var color: UIColor?
  public var blur: UIBlurEffect.Style?
  public var scale: CGFloat?
  public var alpha: CGFloat?
  
  weak var view: DFView?
  weak var blurView: DFVisualEffectView?
  weak var page: SomePage? {
    didSet {
      guard let page = page else { return }
      guard let superview = page.superview else { return }
      let view = DFView()
      view.dframe = page.dframe
      view.addTap(self, #selector(tap))
      superview.insertSubview(view, aboveSubview: page)
      self.view = view
      
      if color != nil {
        view.backgroundColor = .clear
      }
      if blur != nil {
        let blurView = DFVisualEffectView()
        blurView.dframe = screen.dframe
        view.addSubview(blurView)
        self.blurView = blurView
      }
    }
  }
  
  public init() {
    
  }
  public init(color: UIColor) {
    self.color = color
  }
  public init(blur: UIBlurEffect.Style) {
    self.blur = blur
  }
  public init(scale: CGFloat) {
    self.scale = scale
  }
  public init(alpha: CGFloat) {
    self.alpha = alpha
  }
  
  func open() {
    guard let page = page else { return }
    if let color = color {
      view!.backgroundColor = color
    }
    if let blur = blur {
      blurView?.effect = UIBlurEffect(style: blur)
    }
    if let alpha = alpha {
      page.alpha = alpha
    }
    if let scale = scale {
      page.scale(scale)
    }
  }
  func close() {
    guard let page = page else { return }
    blurView?.effect = nil
    if color != nil {
      view!.backgroundColor = .clear
    }
    page.alpha = 1.0
    page.scale(1.0)
  }
  func closed() {
    view?.removeFromSuperview()
  }
  @objc func tap() {
    _main.back()
  }
}
#endif
