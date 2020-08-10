#if os(iOS)
//
//  UIColor.swift
//  Some
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIColor {
  
  public static var mainBackground = UIColor.custom(0xF9F9F9)
  public static var navigationBackground = UIColor(white: 1.0, alpha: 0.2)
  public static var background = UIColor.custom(0xf8f8f8)
  public static var highlighted = UIColor(white: 1.0, alpha: 0.2)
  public static var light = UIColor.white
  public static var line = UIColor.black(0.13)
  public static var dark = UIColor.custom(0x4B4D52) // 4B4D52
  public static var placeholder = UIColor.custom(0xa2a2a2)
  
  public static var customLightGray = UIColor.custom(0xebebeb)
  public static var customGray = UIColor.custom(0xB6B8BC)
  public static var customGreen = UIColor.custom(0x63FF63)
  public static var customYellow = UIColor.custom(0xFFFF63)
  public static var customRed = UIColor.custom(0xFF6363)
  
  public static var hashtag = UIColor.custom(0x2284B4)
  public static var hashtagSymbol = UIColor.custom(0x66bdd3)
  
  public static var system = UIView().tintColor!
  
  public static func hex(_ value: UInt64) -> UIColor {
    
    /// 0xffffff - rgb.
    /// 0x1ffffffff - rgba.
    /// 0x000000ff counts as rgb so you should add prefix like 0x1000000ff.
      if value > 0xffffff { // rgba
        let r = CGFloat((value & 0xff000000) >> 24) / 0xff
        let g = CGFloat((value & 0x00ff0000) >> 16) / 0xff
        let b = CGFloat((value & 0x0000ff00) >> 08) / 0xff
        let a = CGFloat((value & 0x000000ff) >> 00) / 0xff
        return UIColor(red: r, green: g, blue: b, alpha: a)
      } else { // rgb
        let r = CGFloat((value & 0x00ff0000) >> 16) / 0xff
        let g = CGFloat((value & 0x0000ff00) >> 08) / 0xff
        let b = CGFloat((value & 0x000000ff) >> 00) / 0xff
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
      }
  }
  public static func rgba(_ hex: UInt) -> UIColor {
    return UIColor(red: CGFloat((hex & 0xFF000000) >> 24)/255, green: CGFloat((hex & 0xFF0000) >> 16)/255, blue: CGFloat((hex & 0xFF00) >> 8)/255, alpha: CGFloat(hex & 0xFF)/255)
  }
  public static func custom(_ rgb: UInt, alpha: CGFloat = 1) -> UIColor {
    let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
    let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
    let b = CGFloat( rgb & 0x0000FF)        / 255
    return UIColor(red: r, green: g, blue: b, alpha: alpha)
  }
  public static func randomForWhite() -> UIColor {
    var r, g, b: CGFloat
    while true {
      r = .seed()
      g = .seed()
      b = .seed()
      let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
      if luma < 0.8 {
        return UIColor(red: r, green: g, blue: b, alpha: 1)
      }
    }
  }
  public static func randomForWhite(seed: Int) -> UIColor {
    var r, g, b: CGFloat
    while true {
      r = .seed(seed, 1)
      g = .seed(seed, 2)
      b = .seed(seed, 3)
      let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
      if luma < 0.8 {
        return UIColor(red: r, green: g, blue: b, alpha: 1)
      }
    }
  }
  public static func black(_ alpha: CGFloat) -> UIColor {
    return UIColor(white: 0, alpha: alpha)
  }
  public static func white(_ alpha: CGFloat) -> UIColor {
    return UIColor(white: 1, alpha: alpha)
  }
  public static func gray(_ white: CGFloat) -> UIColor {
    return UIColor(white: white, alpha: 1)
  }
  //  public static var light: UIColor { .light }
  //  public static var dark: UIColor { .dark }
  
  public static func == (l: UIColor, r: UIColor) -> Bool {
    var r1: CGFloat = 0
    var g1: CGFloat = 0
    var b1: CGFloat = 0
    var a1: CGFloat = 0
    l.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    var r2: CGFloat = 0
    var g2: CGFloat = 0
    var b2: CGFloat = 0
    var a2: CGFloat = 0
    r.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
  }
}
public func == (l: UIColor?, r: UIColor?) -> Bool {
  let l = l ?? .clear
  let r = r ?? .clear
  return l == r
}

extension Int {
  public var color: UIColor {
    return .custom(UInt(self))
  }
}

#endif
