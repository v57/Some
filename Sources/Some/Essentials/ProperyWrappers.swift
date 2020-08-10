//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 09.03.2020.
//

import Foundation

@propertyWrapper
public enum Lazy<Value> {
  case uninitialized(() -> Value)
  case initialized(Value)

  public init(wrappedValue: @autoclosure @escaping () -> Value) {
    self = .uninitialized(wrappedValue)
  }

  public var projectedValue: Value? {
    switch self {
    case .uninitialized:
      return nil
    case .initialized(let value):
      return value
    }
  }
  public var wrappedValue: Value {
    mutating get {
      switch self {
      case .uninitialized(let initializer):
        let value = initializer()
        self = .initialized(value)
        return value
      case .initialized(let value):
        return value
      }
    }
    set {
      self = .initialized(newValue)
    }
  }
}

@propertyWrapper
public struct Locked<T> {
  public let locker = NSLock()
  public var _wrappedValue: T
  public var wrappedValue: T {
    get {
      locker.lock {
        _wrappedValue
      }
    }
    set {
      locker.lock {
        _wrappedValue = newValue
      }
    }
  }
  public init(wrappedValue: T) {
    _wrappedValue = wrappedValue
  }
}
