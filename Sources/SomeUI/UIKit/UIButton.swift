#if os(iOS)
//
//  UIButton.swift
//  Some
//
//  Created by Димасик on 18/08/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

private var handle = 0
public extension UIButton {
  @objc override func onTouch(_ action: @escaping ()->()) {
    add(on: .touchUpInside, action: action)
  }
  func add(on controlEvents: UIControl.Event, action: @escaping ()->()) {
    let closureSelector = EmptyClosureSelector(closure: action)
    objc_setAssociatedObject(self, &handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    self.addTarget(closureSelector, action: closureSelector.selector, for: controlEvents)
  }
  func onTouch(target: Any?, action: Selector) {
    addTarget(target, action: action, for: .touchUpInside)
  }
  //  public convenience init(size: CGSize) {
  //    self.init(frame: CGRect(origin: .zero, size: size))
  //  }
  convenience init(image: UIImage, highlightedImage: UIImage?, target: Any?, selector: Selector) {
    self.init(frame: CGRect(origin: .zero, size: image.size))
    setImage(image, for: .normal)
    if highlightedImage != nil {
      setImage(highlightedImage, for: .highlighted)
    }
    if target != nil {
      onTouch(target: target, action: selector)
    }
  }
  
  convenience init(name: String) {
    let image = UIImage(named: name)!
    let s: CGFloat = 20
    let w = image.width
    let h = image.height
    let fw = w + s
    let fh = h + s
    let frame = Rect(0,0,fw,fh)
    self.init(frame: frame)
    setImage(image, for: .normal)
  }
  convenience init(image: UIImage) {
    let s: CGFloat = 20
    let w = image.width
    let h = image.height
    let fw = w + s
    let fh = h + s
    let frame = Rect(0,0,fw,fh)
    self.init(frame: frame)
    setImage(image, for: .normal)
  }
  convenience init(text: String, color: Color, font: UIFont) {
    let size = text.size(font)
    let s: CGFloat = 20
    let w = size.width
    let h = size.height
    let fw = w + s
    let fh = h + s
    self.init(type: .system)
    self.frame.size = Size(fw,fh)
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
  }
  convenience init(text: String) {
    self.init(type: .system)
    setTitle(text, for: .normal)
    sizeToFit()
  }
  convenience init(pos: Pos, anchor: Anchor, name: String) {
    let image = UIImage(named: name)!
    let s: CGFloat = 20
    let w = image.width
    let h = image.height
    let fw = w + s
    let fh = h + s
    let x = pos.x - w * anchor.x - s * 0.5
    let y = pos.y - h * anchor.y - s * 0.5
    let frame = Rect(x,y,fw,fh)
    self.init(frame: frame)
    setImage(image, for: .normal)
  }
  convenience init(pos: Pos, anchor: Anchor, image: UIImage) {
    let s: CGFloat = 20
    let w = image.width
    let h = image.height
    let fw = w + s
    let fh = h + s
    let x = pos.x - w * anchor.x - s * 0.5
    let y = pos.y - h * anchor.y - s * 0.5
    let frame = Rect(x,y,fw,fh)
    self.init(frame: frame)
    setImage(image, for: .normal)
  }
  convenience init(pos: Pos, anchor: Anchor, text: String, font: UIFont, color: Color) {
    let size = text.size(font)
    let s: CGFloat = 20
    let w = size.width
    let h = size.height
    let fw = w + s
    let fh = h + s
    let x = pos.x - w * anchor.x - s * 0.5
    let y = pos.y - h * anchor.y - s * 0.5
    let frame = Rect(x,y,fw,fh)
    self.init(type: .system)
    self.frame = frame
    setTitle(text, for: .normal)
    setTitleColor(color, for: .normal)
    titleLabel!.font = font
  }
  func systemHighlighting() {
    
    adjustsImageWhenHighlighted = false
    
    addTarget(self, action: #selector(down), for: .touchDown)
    addTarget(self, action: #selector(down), for: .touchDragEnter)
    addTarget(self, action: #selector(up), for: .touchDragExit)
    addTarget(self, action: #selector(up), for: .touchUpInside)
    addTarget(self, action: #selector(cancel), for: .touchCancel)
  }
  
  func set(text: String) {
    setTitle(text, for: .normal)
    resize(text.size(titleLabel!.font!) + CGSize(20,20), .center)
  }
}

private extension UIButton {
  @objc func cancel() {
    animate {
      self.scale(1)
    }
  }
  
  @objc func up() {
    self.scale(0.8)
    jellyAnimation {
      self.scale(1)
    }
  }
  
  @objc func down() {
    self.scale(1)
    jellyAnimation {
      self.scale(0.8)
    }
  }
}
#endif
