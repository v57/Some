//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/8/20.
//

import Swift

public extension FloatingPoint {
  var fraction: Self { remainder(dividingBy: 1) }
  func devide(by: Self) -> Self { self / by }
}

public extension FloatingPoint where Self: CVarArg {
  func precision(_ precision: Int) -> String {
    String(format: "%.\(precision)f", self)
  }
}
