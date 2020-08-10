#if os(iOS)
//
//  AttributedString.swift
//  Some
//
//  Created by Dmitry on 19/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

public extension String {
  static var defaultAttributes = setDefaultAttributes
  func attributed(_ attributes: (inout StringAttributes)->()) -> AString {
    var editor = StringAttributes()
    String.defaultAttributes(&editor)
    attributes(&editor)
    return AString(string: self, attributes: editor.attributes)
  }
  func attributed() -> AString {
    var editor = StringAttributes()
    String.defaultAttributes(&editor)
    return AString(string: self, attributes: editor.attributes)
  }
  
  private static func setDefaultAttributes(_ attributes: inout StringAttributes) {
    
  }
}

public typealias AString = NSAttributedString
public typealias MString = NSMutableAttributedString
public extension MString {
  @discardableResult
  func line<T: CustomStringConvertible>(_ text: T, _ color: UIColor) -> Self {
    line(text, { $0.foregroundColor = color })
  }
  @discardableResult
  func space<T: CustomStringConvertible>(_ text: T, _ color: UIColor) -> Self {
    space(text, { $0.foregroundColor = color })
  }
  @discardableResult
  func append<T: CustomStringConvertible>(_ text: T, separator: String, _ color: UIColor) -> Self {
    append(text, separator: separator, { $0.foregroundColor = color })
  }
  @discardableResult
  func line<T: CustomStringConvertible>(_ text: T, _ attributes: ((inout StringAttributes)->())? = nil) -> Self {
    append(text, separator: "\n", attributes)
  }
  @discardableResult
  func space<T: CustomStringConvertible>(_ text: T, _ attributes: ((inout StringAttributes)->())? = nil) -> Self {
    append(text, separator: " ", attributes)
  }
  @discardableResult
  func append<T: CustomStringConvertible>(_ text: T, separator: String, _ attributes: ((inout StringAttributes)->())? = nil) -> Self {
    if let attributes = attributes {
      if length == 0 {
        append(text.description.attributed(attributes))
      } else {
        append((separator + text.description).attributed(attributes))
      }
    } else {
      if length == 0 {
        append(AString(string: text.description, attributes: nil))
      } else {
        append(AString(string: separator + text.description, attributes: nil))
      }
    }
    return self
  }
  static func += (left: MString, right: AString) {
    left.append(right)
  }
}

public typealias TextAttributes = [AString.Key: Any]
public struct StringAttributes {
  public var attributes = TextAttributes()
  public var font: UIFont? {
    get { attributes[.font] as? UIFont  }
    set { attributes[.font] = newValue }
  }
  public var paragraphStyle: NSParagraphStyle {
    get { attributes[.paragraphStyle] as? NSParagraphStyle ?? .default  }
    set { attributes[.paragraphStyle] = newValue }
  }
  public var foregroundColor: UIColor {
    get { attributes[.foregroundColor] as? UIColor ?? .black }
    set { attributes[.foregroundColor] = newValue }
  }
  public var backgroundColor: UIColor? {
    get { attributes[.backgroundColor] as? UIColor  }
    set { attributes[.backgroundColor] = newValue }
  }
  public var ligature: Int {
    get { attributes[.ligature] as? Int ?? 0 }
    set { attributes[.ligature] = newValue }
  }
  public var kern: Double {
    get { attributes[.kern] as? Double ?? 0.0  }
    set { attributes[.kern] = newValue }
  }
  public var strikethroughStyle: Int {
    get { attributes[.strikethroughStyle] as? Int ?? 0  }
    set { attributes[.strikethroughStyle] = newValue }
  }
  public var underlineStyle: Int {
    get { attributes[.underlineStyle] as? Int ?? 0  }
    set { attributes[.underlineStyle] = newValue }
  }
  public var strokeColor: UIColor? {
    get { attributes[.strokeColor] as? UIColor  }
    set { attributes[.strokeColor] = newValue }
  }
  public var strokeWidth: Double {
    get { attributes[.strokeWidth] as? Double ?? 0.0  }
    set { attributes[.strokeWidth] = newValue }
  }
  public var shadow: NSShadow? {
    get { attributes[.shadow] as? NSShadow  }
    set { attributes[.shadow] = newValue }
  }
  public var textEffect: String? {
    get { attributes[.textEffect] as? String  }
    set { attributes[.textEffect] = newValue }
  }
  public var attachment: NSTextAttachment? {
    get { attributes[.attachment] as? NSTextAttachment  }
    set { attributes[.attachment] = newValue }
  }
  public var link: NSURL? {
    get { attributes[.link] as? NSURL  }
    set { attributes[.link] = newValue }
  }
  public var baselineOffset: Double {
    get { attributes[.baselineOffset] as? Double ?? 0.0 }
    set { attributes[.baselineOffset] = newValue }
  }
  public var underlineColor: UIColor? {
    get { attributes[.underlineColor] as? UIColor  }
    set { attributes[.underlineColor] = newValue }
  }
  public var strikethroughColor: UIColor? {
    get { attributes[.strikethroughColor] as? UIColor  }
    set { attributes[.strikethroughColor] = newValue }
  }
  public var obliqueness: Double {
    get { attributes[.obliqueness] as? Double ?? 0.0  }
    set { attributes[.obliqueness] = newValue }
  }
  public var expansion: Double {
    get { attributes[.expansion] as? Double ?? 0.0  }
    set { attributes[.expansion] = newValue }
  }
  public var verticalGlyphForm: Int {
    get { attributes[.verticalGlyphForm] as? Int ?? 0  }
    set { attributes[.verticalGlyphForm] = newValue }
  }
}

public extension AString {
  static func with(text: String, font: UIFont? = nil, color: UIColor? = nil) -> AString {
    var attributes = TextAttributes()
    if let font = font {
      attributes[.font] = font
    }
    if let color = color {
      attributes[.foregroundColor] = color
    }
    return AString(string: text, attributes: attributes)
  }
}
#endif
