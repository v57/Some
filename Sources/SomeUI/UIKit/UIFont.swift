#if os(iOS)
//
//  UIFont.swift
//  Some
//
//  Created by Димасик on 18/08/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UIFont {
  // http://tirania.org/s/a5d82df0.png
  // https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
  convenience init(_ size: CGFloat) {
    let systemFont = UIFont.systemFont(ofSize: size)
    self.init(name: systemFont.fontName, size: size)!
  }
  static var navigationBarLarge: UIFont {
    if #available(iOS 11.0, *) {
      return UIFont.preferredFont(forTextStyle: .largeTitle).heavy
    } else {
      return .heavy(34)
    }
  }
  static var largeTitle: UIFont {
    return .navigationBarLarge
  }
  static var body: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
  }
  static var title1: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1)
  }
  static var title2: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title2)
  }
  static var title3: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title3)
  }
  static var footnote: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
  }
  static var headline: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
  }
  static var subheadline: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)
  }
  static var callout: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.callout)
  }
  static var caption1: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
  }
  static var caption2: UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
  }
  static func light(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  static func ultraLight(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.ultraLight)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  static func thin(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.thin)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  static func normal(_ size: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: size)
  }
  static func semibold(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.semibold)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  static func bold(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.bold)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  static func heavy(_ size: CGFloat) -> UIFont {
    if #available(iOS 8.2, *) {
      return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.heavy)
    } else {
      return UIFont.systemFont(ofSize: size)
    }
  }
  public static func mono(_ size: CGFloat) -> UIFont {
    if #available(iOS 13.0, *) {
      return .monospacedSystemFont(ofSize: size, weight: .bold)
    } else {
      return UIFont(name: "Menlo", size: size)!
    }
  }
  static func monoNumbers(_ size: CGFloat) -> UIFont {
    if #available(iOS 9.0, *) {
      return UIFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
    } else {
      return UIFont(name: "Menlo", size: size)!
    }
  }
  
  
  var semibold: UIFont {
    return .semibold(pointSize)
  }
  var light: UIFont {
    return .light(pointSize)
  }
  var ultraLight: UIFont {
    return .ultraLight(pointSize)
  }
  var thin: UIFont {
    return .thin(pointSize)
  }
  var normal: UIFont {
    return .normal(pointSize)
  }
  var bold: UIFont {
    return .bold(pointSize)
  }
  var heavy: UIFont {
    return .heavy(pointSize)
  }
  var mono: UIFont {
    return .mono(pointSize)
  }
  var monoNumbers: UIFont {
    return .monoNumbers(pointSize)
  }
}
#endif
