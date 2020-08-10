//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 28/10/2019.
//

import UIKit

public extension UIVisualEffect {
  static var light: UIVisualEffect { UIBlurEffect(style: .light) }
  static var extraLight: UIVisualEffect { UIBlurEffect(style: .extraLight) }
  static var dark: UIVisualEffect { UIBlurEffect(style: .dark) }
  static func style(_ style: UIBlurEffect.Style) -> UIVisualEffect {
    UIBlurEffect(style: style)
  }
}
public extension UIVisualEffectView {
  static var light: UIVisualEffectView { UIVisualEffectView(effect: .light) }
  static var extraLight: UIVisualEffectView { UIVisualEffectView(effect: .extraLight) }
  static var dark: UIVisualEffectView { UIVisualEffectView(effect: .dark) }
  static func style(_ style: UIBlurEffect.Style) -> UIVisualEffectView {
    UIVisualEffectView(effect: .style(style))
  }
}
