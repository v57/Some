#if os(iOS)
//
//  UIImageView.swift
//  Some
//
//  Created by Димасик on 18/08/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIImageView {
  public convenience init(_ imageName: String) {
    self.init(image: UIImage(named: imageName))
  }
  //  public convenience init(size: CGSize) {
  //    self.init(frame: CGRect(0,0,size.width,size.height))
  //  }
  public convenience init(pos: Pos, anchor: Anchor, image: UIImage) {
    self.init(image: image)
    self.move(pos,anchor)
  }
  public convenience init(pos: Pos, anchor: Anchor, name: String) {
    self.init(image: UIImage(named: name))
    self.move(pos,anchor)
  }
  public func animate(_ image: UIImage) {
    guard animationsAvailable() else {
      self.image = image
      return
    }
    let copy = UIImageView(frame: frame)
    copy.clipsToBounds = clipsToBounds
    copy.contentMode = contentMode
    copy.layer.cornerRadius = layer.cornerRadius
    copy.backgroundColor = backgroundColor
    copy.image = self.image
    self.image = image
    alpha = 0.0
    superview?.insertSubview(copy, belowSubview: self)
    UIView.animate(withDuration: 0.15, animations: {
      self.alpha = 1.0
    }, completion: {_ in
      copy.destroy()
    })
  }
  @discardableResult
  public func center() -> Self {
    contentMode = .center
    clipsToBounds = true
    return self
  }
  @discardableResult
  public func aspectFill() -> Self {
    contentMode = .scaleAspectFill
    clipsToBounds = true
    return self
  }
  @discardableResult
  public func aspectFit() -> Self {
    contentMode = .scaleAspectFit
    return self
  }
}
#endif
