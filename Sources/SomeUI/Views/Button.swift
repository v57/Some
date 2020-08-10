
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

open class Button: UIButton {
  open var imageName: String?
  open var handler: (() -> ())? {
    didSet {
      if oldValue == nil {
        onTouch(target: self, action: #selector(touchUpInside))
      }
    }
  }
  open var shows: Bool {
    get {
      return alpha > 0
    }
    set {
      animateif(superview != nil) {
        alpha = newValue ? 1.0 : 0.0
      }
    }
  }
  override public init(frame: CGRect) {
    super.init(frame: frame)
  }
  public init(frame: CGRect, imageName: String) {
    super.init(frame: frame)
    setImage(UIImage(named: imageName), for: .normal)
  }
  public init(frame: CGRect, imageName: String, handler: @escaping () -> ()) {
    super.init(frame: frame)
    setImage(UIImage(named: imageName), for: .normal)
    self.handler = handler
    onTouch(target: self, action: #selector(touchUpInside))
  }
  public init(frame: CGRect, image: UIImage?) {
    super.init(frame: frame)
    setImage(image, for: .normal)
  }
  public init(frame: CGRect, image: UIImage?, handler: @escaping () -> ()) {
    super.init(frame: frame)
    setImage(image, for: .normal)
    self.handler = handler
    onTouch(target: self, action: #selector(touchUpInside))
  }
  public init(frame: CGRect, text: String, font: UIFont, color: UIColor) {
    super.init(frame: frame)
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
  }
  public init(frame: CGRect, text: String, font: UIFont, color: UIColor, handler: @escaping () -> ()) {
    super.init(frame: frame)
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
    self.handler = handler
    onTouch(target: self, action: #selector(touchUpInside))
  }
  public init(frame: CGRect, imageName: String, text: String, font: UIFont, color: UIColor, handler: (()->())! = nil) {
    super.init(frame: frame)
    self.adjustsImageWhenHighlighted = false
    setImage(UIImage(named: imageName), for: .normal)
    imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
    if handler != nil {
      self.handler = handler
      onTouch(target: self, action: #selector(touchUpInside))
    }
  }
  public init(frame: CGRect, image: UIImage, text: String, font: UIFont, color: UIColor) {
    super.init(frame: frame)
    self.adjustsImageWhenHighlighted = false
    setImage(image, for: .normal)
    imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
  }
  
  open func frame(_ frame: CGRect, text: String, font: UIFont, color: UIColor) {
    self.frame = frame
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
  }
  
  open func touch(_ handler: @escaping () -> ()) {
    self.handler = handler
  }
  
  @objc open func touchUpInside() {
    if defaultHighlighting {
      alpha = defaultAlpha
    }
    handler?()
  }
  
  @objc open func touchUpOutside() {
    alpha = defaultAlpha
  }
  
  @objc open func touchDown() {
    alpha = defaultAlphaDown
  }
  
  override open var backgroundColor: UIColor? {
    didSet {
      defaultHighlighting = true
    }
  }
  
  open var defaultHighlighting = false {
    didSet {
      if defaultHighlighting != oldValue {
        removeTarget(self, action: #selector(Button.touchUpOutside), for: .touchUpOutside)
        removeTarget(self, action: #selector(Button.touchUpOutside), for: .touchCancel)
        removeTarget(self, action: #selector(Button.touchUpInside), for: .touchUpInside)
        removeTarget(self, action: #selector(Button.touchDown), for: .touchDown)
        if defaultHighlighting {
          addTarget(self, action: #selector(Button.touchUpInside), for: .touchUpInside)
          addTarget(self, action: #selector(Button.touchUpOutside), for: .touchCancel)
          addTarget(self, action: #selector(Button.touchUpOutside), for: .touchUpOutside)
          addTarget(self, action: #selector(Button.touchDown), for: .touchDown)
        }
      }
    }
  }
  open var defaultAlpha: CGFloat = 1.0
  open var defaultAlphaDown: CGFloat = 0.5
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

open class DFButton2: Button, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPButton2: Button, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

open class DCButton2: Button, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
}

extension UIButton {
  public func animateImage(_ image: UIImage!) {
    guard superview != nil else { return }
    
    let button = UIButton(frame: self.frame)
    button.setImage(self.imageView!.image, for: .normal)
    if layer.borderColor != nil {
      button.layer.borderColor = layer.borderColor
      button.layer.borderWidth = layer.borderWidth
    }
    superview!.insertSubview(button, belowSubview: self)
    
    setImage(image, for: .normal)
    self.alpha = 0.0
    animate ({
      self.alpha = 1.0
    }) {
      button.destroy()
    }
  }
}
