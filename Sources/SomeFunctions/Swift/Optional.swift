//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Swift

public extension Optional {
  mutating func `lazy`(create: ()->(Wrapped), created: (Wrapped)->()) -> Wrapped {
    switch self {
    case .some(let value):
      return value
    case .none:
      let value = create()
      created(value)
      self = .some(value)
      return value
    }
  }
  mutating func `lazy`(_ create: ()->(Wrapped)) -> Wrapped {
    switch self {
    case .some(let value):
      return value
    case .none:
      let value = create()
      self = .some(value)
      return value
    }
  }
  var stringDescription: String {
    switch self {
    case .some(let value):
      return "\(value)"
    case .none:
      return "nil"
    }
  }
}
