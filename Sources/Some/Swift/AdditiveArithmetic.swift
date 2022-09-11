//
//  AdditiveArithmetic.swift
//  
//
//  Created by Dmitry Kozlov on 12.04.2022.
//

import Swift

public extension AdditiveArithmetic {
  func range(_ offset: Self) -> Range<Self> where Self: Comparable {
    let bound = self + offset
    if bound > self {
      return self..<bound
    } else {
      return bound..<self
    }
  }
}
