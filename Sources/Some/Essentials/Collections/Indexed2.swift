//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 09/10/2020.
//

import Swift

public struct Indexed2<Value> {
  public var index: Vector2<Int>
  public var value: Value
  public init(_ firstIndex: Int, _ secondIndex: Int, _ value: Value) {
    self.index = Vector2(firstIndex, secondIndex)
    self.value = value
  }
  public init(_ index: Vector2<Int>, _ value: Value) {
    self.index = index
    self.value = value
  }
  public init(index: Vector2<Int>, value: Value) {
    self.index = index
    self.value = value
  }
}
public extension Indexed2 {
  func map<U>(_ transform: (Value)->(U)) -> Indexed2<U> {
    Indexed2<U>(index, transform(value))
  }
  func singleItemArray() -> Indexed2<[Value]> {
    Indexed2<[Value]>(index, [value])
  }
}
extension Indexed2: ComparsionValue {
  public var _valueToCompare: Vector2<Int> { index }
}

extension Indexed2: DataRepresentable where Value: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(index: data.next(), value: data.next())
  }
  public func save(data: DataWriter) {
    data.append(index)
    data.append(value)
  }
}
extension Indexed2: DataRepresentableVersionable where Value: DataRepresentableVersionable {
  public init(data: DataReader, version: Int) throws {
    try self.init(index: data.next(), value: data.next(version: version))
  }
  public func save(data: DataWriter, version: Int) {
    data.append(index)
    data.append(value, version: version)
  }
}
extension Indexed2: Versionable where Value: Versionable {
  public static var className: String { Value.className }
  public static var version: Int {
    get { Value.version }
    set { Value.version = newValue }
  }
}

