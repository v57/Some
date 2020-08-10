//
//  PageBackground.swift
//  Some
//
//  Created by Димасик on 11/2/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

public enum PageBackground {
  case none
  case color(UIColor)
  case transparent(UIColor)
  case blur(UIBlurEffect.Style)
  var isVisible: Bool {
    switch self {
    case .none: return false
    default: return true
    }
  }
  var isSolid: Bool {
    switch self {
    case .color, .none:
      return true
    default:
      return false
    }
  }
  var raw: Int {
    switch self {
    case .none: return 0
    case .color: return 1
    case .transparent: return 2
    case .blur: return 3
    }
  }
}

extension SomePage {
  public func set(background: PageBackground, animated: Bool) {
    if background.raw != _background.raw {
      _remove(background: _background, animated: animated)
    }
    _background = background
    _set(background: _background, animated: animated)
  }
  private func _set(background: PageBackground, animated: Bool) {
    switch background {
    case .none:
      return
    case .color(let color):
      backgroundColor = color
    case .transparent(let color):
      backgroundColor = color
    case .blur(let blur):
      var view: UIVisualEffectView! = blurBackgroundView
      if view == nil {
        view = UIVisualEffectView()
        view.frame = bounds
        blurBackgroundView = view
        insertSubview(view, at: 0)
      }
      let effect = UIBlurEffect(style: blur)
      animateif(animated) {
        view.effect = effect
      }
    }
  }
  private func _remove(background: PageBackground, animated: Bool) {
    switch background {
    case .none:
      return
    case .color:
      animateif(animated) {
        backgroundColor = .clear
      }
    case .transparent:
      animateif(animated) {
        backgroundColor = .clear
      }
    case .blur:
      guard let view = blurBackgroundView else { return }
      if animated {
        animate ({
          view.effect = nil
        }) {
          view.removeFromSuperview()
          self.blurBackgroundView = nil
        }
      } else {
        view.removeFromSuperview()
        blurBackgroundView = nil
      }
    }
  }
}


