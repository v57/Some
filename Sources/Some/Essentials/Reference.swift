//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 17/10/2020.
//

import Foundation

@propertyWrapper
@dynamicMemberLookup
public class Reference<Value> {
  public var value: Value
  public init(initialValue: Value) {
    value = initialValue
  }
  public init(wrappedValue: Value) {
    value = wrappedValue
  }
  public init(_ value: Value) {
    self.value = value
  }
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
    get { value[keyPath: keyPath] }
    set { value[keyPath: keyPath] = newValue }
  }
  public var projectedValue: Reference<Value> { self }
  public var wrappedValue: Value {
    get { value }
    set { value = newValue }
  }
}
