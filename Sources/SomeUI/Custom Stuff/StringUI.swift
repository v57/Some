#if os(iOS)
//
//  StringUI.swift
//  Some
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension String {
  public var range: NSRange {
    NSRange(location: 0, length: (self as NSString).length)
  }
  public func size(_ font: UIFont) -> CGSize {
    return self.size(withAttributes: [AString.Key.font : font])
  }
  public func width(_ font: UIFont) -> CGFloat {
    return self.size(withAttributes: [AString.Key.font : font]).width
  }
  public func height(_ font: UIFont, width: CGFloat) -> CGFloat {
    return self.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [AString.Key.font: font], context: nil).h
  }
  public func numberOfLines(_ font: UIFont, width: CGFloat) -> Int {
    return Int(self.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [AString.Key.font: font], context: nil).h / font.lineHeight)
  }
  public func size(_ font: UIFont, maxWidth: CGFloat) -> CGSize {
    guard maxWidth > 0 else { return size(font) }
    let attributes = [AString.Key.font: font]
    var width: CGFloat = 0
    let container = NSTextContainer(size: CGSize(maxWidth,.greatestFiniteMagnitude))
    let layout = NSLayoutManager()
    let storage = NSTextStorage(string: self, attributes: attributes)
    storage.addLayoutManager(layout)
    layout.addTextContainer(container)
    var height: CGFloat = 0
    layout.enumerateLineFragments(forGlyphRange: NSRange(location: 0,length: self.count), using: { rect, rect2, cont, rang, stop in
      height += rect2.h
      width = Swift.max(rect2.w,width)
    })
    return CGSize(width,height)
  }
  public func image(font: UIFont) -> UIImage {
    let size = self.size(font)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }
    //    UIColor.white.set()
    let rect = CGRect(origin: .zero, size: size)
    //    UIRectFill(rect)
    (self as NSString).draw(in: rect, withAttributes: [AString.Key.font: font])
    return UIGraphicsGetImageFromCurrentImageContext()!
  }
  
  public func saveToClipboard() {
    UIPasteboard.general.string = self
  }
}
public class TextLayout {
  public var text: String {
    didSet {
      guard text != oldValue else { return }
      _size = nil
      storage = NSTextStorage(string: text, attributes: attributes)
    }
  }
  public var width: CGFloat {
    didSet {
      guard width != oldValue else { return }
      _size = nil
      container = NSTextContainer(size: CGSize(width, .greatestFiniteMagnitude))
    }
  }
  public var attributes: [NSAttributedString.Key : Any]? {
    didSet {
      _size = nil
      storage = NSTextStorage(string: text, attributes: attributes)
    }
  }
  public var onlyHeight = false
  public let layout = NSLayoutManager()
  public var _size: CGSize?
  public var size: CGSize {
    if let _size = _size {
      return _size
    } else {
      if onlyHeight {
        var height: CGFloat = 0
        layout.enumerateLineFragments(forGlyphRange: text.range, using: { rect, rect2, cont, rang, stop in
          height += rect2.size.height
        })
        height.round(.up)
        let size = CGSize(width, height)
        _size = size
        return size
      } else {
        var size = CGSize.zero
        layout.enumerateLineFragments(forGlyphRange: text.range, using: { rect, rect2, cont, rang, stop in
          size.height += rect2.size.height
          size.width = Swift.max(rect2.size.width, size.width)
        })
        size = CGSize(size.width.rounded(.up), size.height.rounded(.up))
        _size = size
        return size
      }
    }
  }
  public var storage: NSTextStorage? {
    didSet {
      oldValue?.removeLayoutManager(layout)
      if let storage = storage {
        storage.addLayoutManager(layout)
      }
    }
  }
  public var container: NSTextContainer? {
    didSet {
      guard container != oldValue else { return }
      if layout.textContainers.count > 0 {
        layout.removeTextContainer(at: 0)
      }
      if let container = container {
        layout.addTextContainer(container)
      }
    }
  }
  public init(text: String = "", width: CGFloat = 0, attributes: [NSAttributedString.Key : Any]? = nil) {
    self.text = text
    self.width = width
    self.attributes = attributes
  }
  public func size(text: String, width: CGFloat) -> CGSize {
    self.text = text
    self.width = width
    return size
  }
  public func height(text: String, width: CGFloat) -> CGFloat {
    onlyHeight = true
    self.text = text
    self.width = width
    return size.height
  }
}

public class ATextLayout {
  public var text: AString {
    didSet {
      guard text != oldValue else { return }
      _size = nil
      storage = NSTextStorage(attributedString: text)
    }
  }
  public var width: CGFloat {
    didSet {
      guard width != oldValue else { return }
      _size = nil
      container = NSTextContainer(size: CGSize(width, .greatestFiniteMagnitude))
    }
  }
  public var onlyHeight = false
  public let layout = NSLayoutManager()
  public var _size: CGSize?
  public var size: CGSize {
    if let _size = _size {
      return _size
    } else {
      let range = NSRange(location: 0, length: text.length)
      if onlyHeight {
        var height: CGFloat = 0
        layout.enumerateLineFragments(forGlyphRange: range, using: { rect, rect2, cont, rang, stop in
          height += rect2.size.height
        })
        height.round(.up)
        let size = CGSize(width, height)
        _size = size
        return size
      } else {
        var size = CGSize.zero
        layout.enumerateLineFragments(forGlyphRange: range, using: { rect, rect2, cont, rang, stop in
          size.height += rect2.size.height
          size.width = Swift.max(rect2.size.width, size.width)
        })
        size = CGSize(size.width.rounded(.up), size.height.rounded(.up))
        _size = size
        return size
      }
    }
  }
  public var storage: NSTextStorage? {
    didSet {
      oldValue?.removeLayoutManager(layout)
      if let storage = storage {
        storage.addLayoutManager(layout)
      }
    }
  }
  public var container: NSTextContainer? {
    didSet {
      guard container != oldValue else { return }
      if layout.textContainers.count > 0 {
        layout.removeTextContainer(at: 0)
      }
      if let container = container {
        layout.addTextContainer(container)
      }
    }
  }
  public init(text: AString = AString(), width: CGFloat = 0) {
    self.text = text
    self.width = width
  }
  public func size(text: AString, width: CGFloat) -> CGSize {
    self.text = text
    self.width = width
    return size
  }
  public func height(text: AString, width: CGFloat) -> CGFloat {
    onlyHeight = true
    self.text = text
    self.width = width
    return size.height
  }
}
#endif
