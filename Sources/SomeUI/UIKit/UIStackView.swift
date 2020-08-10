#if os(iOS)
//
//  UIStackView.swift
//  Some
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

public extension UIStackView {
  @discardableResult
  func alignment(_ alignment: Alignment) -> Self {
    self.alignment = alignment
    return self
  }
  @discardableResult
  func vertical() -> Self {
    axis = .vertical
    return self
  }
  @discardableResult
  func center() -> Self {
    alignment = .center
    return self
  }
  @discardableResult
  func horizontal() -> Self {
    axis = .horizontal
    return self
  }
  @discardableResult
  func spacing(_ spacing: CGFloat, after view: UIView) -> Self {
    if #available(iOS 11.0, *) {
      setCustomSpacing(spacing, after: view)
    } else {
      // Fallback on earlier versions
    }
    return self
  }
  @discardableResult
  func spacing(_ spacing: CGFloat) -> Self {
    self.spacing = spacing
    return self
  }
  @discardableResult
  func distribution(_ distribution: Distribution) -> Self {
    self.distribution = distribution
    return self
  }
}
#endif
