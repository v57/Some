//
//  UILabel.swift
//  Some
//
//  Created by Димасик on 18/08/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UILabel {
  
  convenience init(text: String, color: Color, font: UIFont, resize: Bool) {
    let size = text.size(font)
    self.init(frame: resize ? Rect(origin: .zero, size: size) : .zero)
    self.text = text
    self.textColor = color
    self.font = font
  }
  convenience init(text: String, color: Color, font: UIFont) {
    let size = text.size(font)
    self.init(frame: Rect(origin: .zero, size: size))
    self.text = text
    self.textColor = color
    self.font = font
  }
  convenience init(text: String, color: Color, font: UIFont, maxWidth: CGFloat, numberOfLines: Int) {
    var size = text.size(font)
    if size.width > maxWidth {
      size.width = maxWidth
      size.height = text.height(font, width: maxWidth)
      
      if numberOfLines > 0 {
        let maxHeight = CGFloat(numberOfLines) * font.lineHeight
        if size.height > maxHeight {
          size.height = maxHeight
        }
      }
    }
    self.init(frame: Rect(origin: .zero, size: size))
    self.numberOfLines = numberOfLines
    self.text = text
    self.textColor = color
    self.font = font
  }
  convenience init(text: String, color: Color, font: UIFont, maxWidth: CGFloat) {
    let size = text.size(font)
    self.init(frame: Rect(origin: .zero, size: CGSize(min(size.width,maxWidth),size.height)))
    self.text = text
    self.textColor = color
    self.font = font
  }
  convenience init(pos: Pos, anchor: Anchor, text: String, color: Color, font: UIFont) {
    let size = text.size(font)
    self.init(frame: Rect(pos, anchor, size))
    self.text = text
    self.textColor = color
    self.font = font
    self.textAlignment = anchor.alignment
  }
  convenience init(pos: Pos, anchor: Anchor, text: String, color: Color, font: UIFont, maxWidth: CGFloat) {
    let size = text.size(font)
    self.init(frame: Rect(pos, anchor, CGSize(min(size.width,maxWidth),size.height)))
    self.text = text
    self.textColor = color
    self.font = font
    self.textAlignment = anchor.alignment
  }
  convenience init(frame: CGRect, text: String?, font: UIFont, color: UIColor, alignment: NSTextAlignment) {
    self.init(frame: frame)
    self.text = text
    self.font = font
    self.textColor = color
    self.textAlignment = alignment
  }
  convenience init(frame: CGRect, text: String?, font: UIFont, color: UIColor, alignment: NSTextAlignment, fixHeight: Bool) {
    self.init(frame: UILabel.fixFrame(frame, text: text as NSString? ?? "", font: font, textAlignment: alignment, fixHeight: fixHeight))
    self.text = text
    self.font = font
    self.textColor = color
    self.textAlignment = alignment
  }
  func fixFrame(_ fixHeight: Bool) {
    self.frame = UILabel.fixFrame(self.frame, text: self.text! as NSString, font: self.font, textAlignment: self.textAlignment, fixHeight: fixHeight)
  }
  func autoresizeFont() {
    adjustsFontSizeToFitWidth = true
    minimumScaleFactor = 0.5
  }
  func set(text: String, anchor: Anchor, maxWidth: CGFloat = 0) {
    let frame = self.frame
    self.text = text
    
    var size = CGSize.zero
    size.width = text.width(font)
    size.height = text.height(font, width: maxWidth)
    if maxWidth > 0 {
      size.width = min(size.width,maxWidth)
      if numberOfLines > 0 {
        size.height = min(size.height, font.lineHeight * CGFloat(numberOfLines))
      }
    }
    
    self.frame.size = size
    move(frame.anchor(anchor), anchor)
  }
  var animateText: String {
    get {
      return text!
    }
    set {
      defer { text = newValue }
      guard superview != nil else { return }
      let fake = UILabel(frame: frame, text: text!, font: font, color: textColor, alignment: textAlignment)
      fake.numberOfLines = self.numberOfLines
      superview!.addSubview(fake)
      alpha = 0
      animate ({
        fake.alpha = 0
      }) {
        fake.removeFromSuperview()
        self.animate {
          self.alpha = 1
        }
      }
    }
  }
  
  private class func fixFrame(_ frame: CGRect, text: NSString, font: UIFont, textAlignment: NSTextAlignment, fixHeight: Bool) -> CGRect { // frame.size can be (0,0)
    let size = text.size(withAttributes: [AString.Key.font : font])
    var x = frame.x
    var y = frame.y
    var w = frame.w
    var h = frame.h
    switch (textAlignment) {
    case NSTextAlignment.left:
      break
    case NSTextAlignment.center:
      x += (w - size.width) / 2.0
      break
    case NSTextAlignment.right:
      x += w - size.width
      break
      
    default:
      break
    }
    w = size.width;
    if fixHeight {
      y += (h - size.height) / 2.0
      h = size.height
    }
    return CGRect(x: x, y: y, width: w, height: h);
  }
}
