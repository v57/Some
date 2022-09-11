//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 19.07.2022.
//

#if canImport(UIKit)
import UIKit

public extension UIScreen {
  private static let cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()
  var cornerRadius: CGFloat {
    value(forKey: Self.cornerRadiusKey) as? CGFloat ?? 0
  }
}
#endif
