//
//  MacView.swift
//  Some
//
//  Created by Димасик on 11/15/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

open class MacView: UIView, DynamicFrame {
  public var dynamicFrame: DFrame?
  var blurView: UIVisualEffectView?
  var gradientView: UIView
  lazy var gradientLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    switch style {
    case .solid:
      layer.colors = [MacView.sTop.cgColor, MacView.sBottom.cgColor]
    default:
      layer.colors = [MacView.tTop.cgColor, MacView.tBottom.cgColor]
    }
    self.gradientView.layer.addSublayer(layer)
    return layer
  }()
  
  static var tTop: UIColor {
    return .black(0.08)
  }
  static var tBottom: UIColor {
    return .black(0.18)
  }
  static var sTop: UIColor {
    return 0xEBEBEB.color
  }
  static var sBottom: UIColor {
    return 0xEBEBEB.color
  }
  
  let style: Style
  public init(style: Style) {
    self.style = style
    gradientView = UIView(frame: .zero)
    super.init(frame: .zero)
    clipsToBounds = true
    if let effect = style.effect {
      blurView = UIVisualEffectView(effect: effect)
      addSubview(blurView!)
    }
    addSubview(gradientView)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func resolutionChanged() {
    super.resolutionChanged()
    blurView?.frame = bounds
    gradientView.frame = bounds
    gradientLayer.frame = bounds
  }
  
  public enum Style {
    case solid, light, extraLight
    var effect: UIVisualEffect? {
      switch self {
      case .solid: return nil
      case .light: return UIBlurEffect(style: .light)
      case .extraLight: return UIBlurEffect(style: .extraLight)
      }
    }
  }
}
