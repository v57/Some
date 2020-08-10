//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/8/20.
//

import Swift

public extension FloatingPoint {
  var fraction: Self {
    let remainder = self.remainder(dividingBy: 1)
    return remainder < 0 ? remainder + 1 : remainder
  }
  func devide(by: Self) -> Self { self / by }
}

public extension FloatingPoint where Self: CVarArg {
  func precision(_ precision: Int) -> String {
    String(format: "%.\(precision)f", self)
  }
}
