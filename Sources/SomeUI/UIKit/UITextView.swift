//
//  UITextView.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UITextView {
  public convenience init(text: String, font: UIFont, width: CGFloat, minWidth: CGFloat, insets: UIEdgeInsets) {
    self.init(frame: CGRect(0,0,width,0))
    
    self.textContainerInset = insets
    self.text = text
    self.font = font
    
    var width: CGFloat = 0
    layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: 0,length: text.count), using: { rect, rect2, cont, rang, some in
      width = max(rect2.w + 10,width)
    })
    self.sizeToFit()
    frame = CGRect(0,0,max(frame.w, minWidth),contentSize.height)
    
    isScrollEnabled = false
    isEditable = false
    isSelectable = false
  }
}
