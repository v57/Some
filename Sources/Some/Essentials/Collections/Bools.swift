//
//  Bools.swift
//  SomeFunctions
//
//  Created by Dmitry on 03/06/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

public struct Bools: RawRepresentable {
  public var count = 0
  public var rawValue = 0
  public init() {}
  public init?(rawValue: Int) {
    self.rawValue = rawValue
  }
  public func contains(_ bool: Bool) -> Bool {
    return firstIndex(of: bool) != nil
  }
  public func firstIndex(of bool: Bool) -> Int? {
    for i in 0..<count {
      if rawValue[i] == bool {
        return i
      }
    }
    return nil
  }
  public mutating func append(_ element: Bool) {
    rawValue[count] = element
    count += 1
  }
  public subscript(index: Int) -> Bool {
    get { rawValue[index] }
    set { rawValue[index] = newValue }
  }
  public func enumerated(_ action: (Int,Bool)->()) {
    for i in 0..<count {
      action(i,rawValue[i])
    }
  }
  public func forEach(_ action: (Bool)->()) {
    for i in 0..<count {
      action(rawValue[i])
    }
  }
}
public extension Bool {
  static func |=(l: inout Bool, r: Bool) {
    l = l || r
  }
  var int: Int { self ? 1 : 0 }
}
