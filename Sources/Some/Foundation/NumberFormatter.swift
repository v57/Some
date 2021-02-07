//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 14/12/2020.
//

import Foundation

#if os(iOS)
public extension Int {
  func string(using formatter: NumberFormatter) -> String {
    return formatter.string(from: NSNumber(integerLiteral: self))!
  }
}
public extension NumberFormatter {
  static let spaces: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.formatterBehavior = .behavior10_4
    numberFormatter.groupingSeparator = " "
    numberFormatter.numberStyle = .decimal
    return numberFormatter
  }()
}
#endif
