//
//  options.swift
//  SomeFunctions
//
//  Created by Димасик on 12/15/17.
//

import Swift

extension UInt8 {
  public func optionSet<T>() -> Set<T> where T: RawRepresentable, T.RawValue == UInt8 {
    var set = Set<T>()
    for i in UInt8(0)..<UInt8(8) {
      guard self[i] else { continue }
      guard let value = T(rawValue: i) else { break }
      set.insert(value)
    }
    return set
  }
}

public extension RawRepresentable where RawValue: BinaryInteger {
  static var count: Int {
    var i: RawValue = 0
    while Self(rawValue: i) != nil {
      i += 1
    }
    return Int(i)
  }
  static var random: Self {
    Self(rawValue: RawValue(Int.random(in: 0..<count)))!
  }
  static func all() -> [Self] {
    var i: RawValue = 0
    var array = [Self]()
    while let value = Self(rawValue: i) {
      array.append(value)
      i += 1
    }
    return array
  }
  static func forEach(_ action: (Self)->()) {
    var i: RawValue = 0
    while let value = Self(rawValue: i) {
      action(value)
      i += 1
    }
  }
  static func map<T>(_ transform: (Self)->(T)) -> [T] {
    return all().map(transform)
  }
}

public extension RawRepresentable where RawValue: Comparable {
  static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  static func <=(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  static func >=(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }
  static func >(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
}

extension RawRepresentable where RawValue == UInt8 {
  public typealias Set = Options<Self,UInt8>
  public typealias Set16 = Options<Self,UInt16>
  public typealias Set32 = Options<Self,UInt32>
  public typealias Set64 = Options<Self,UInt64>
  public typealias IntSet = Options<Self,Int>
  public var int: Int { Int(rawValue) }
}
public extension Array where Element: RawRepresentable, Element.RawValue == UInt8 {
  func optionSet() -> Element.Set { Options(self) }
  func optionSet() -> Element.Set16 { Options(self) }
  func optionSet() -> Element.Set32 { Options(self) }
  func optionSet() -> Element.Set64 { Options(self) }
}


public extension Sequence where Element: RawRepresentable, Element.RawValue: BinaryInteger {
  func options() -> Int {
    var result = 0
    for i in self {
      result[i.rawValue] = true
    }
    return result
  }
}
public extension Sequence where Element: BinaryInteger {
  func options() -> Int {
    var result = 0
    for i in self {
      result[i] = true
    }
    return result
  }
}

extension BinaryInteger {
  public subscript<T: BinaryInteger>(index: T) -> Bool {
    get {
      return self & (1 << index) != 0
    }
    set {
      if newValue {
        self |= 1 << index
      } else {
        self &= ~(1 << index)
      }
    }
  }
}

// MARK:- Options
public struct Options<Enum,RawValue>: RawRepresentable
where Enum: RawRepresentable, RawValue: BinaryInteger, Enum.RawValue == UInt8 {
  public var rawValue: RawValue
  public var isEmpty: Bool {
    return rawValue == 0
  }
  public var first: Enum? { Enum(rawValue: UInt8(rawValue.trailingZeroBitCount)) }
  public init() {
    rawValue = 0
  }
  public init(_ array: [Enum]) {
    rawValue = 0
    for v in array {
      rawValue[v.rawValue] = true
    }
  }
  public init(_ array: Enum...) {
    rawValue = 0
    for v in array {
      rawValue[v.rawValue] = true
    }
  }
  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }
  public subscript(_ value: Enum) -> Bool {
    get {
      return contains(value)
    } set {
      if newValue {
        insert(value)
      } else {
        remove(value)
      }
    }
  }
  
  public func forEach(_ body: (Enum) -> ()) {
    Enum.forEach {
      if self[$0] {
        body($0)
      }
    }
  }
  public func map<T>(_ transform: (Enum) -> (T)) -> [T] {
    var result = [T]()
    forEach { element in
      result.append(transform(element))
    }
    return result
  }
  
  /// |
  public func union(_ other: Options) -> Options {
    return Options(rawValue: rawValue | other.rawValue)
  }
  
  /// &
  public func intersection(_ other: Options) -> Options {
    return Options(rawValue: rawValue & other.rawValue)
  }
  
  /// ^ returns set of changed values
  public func symmetricDifference(_ other: Options) -> Options {
    return Options(rawValue: rawValue ^ other.rawValue)
  }
  
  public mutating func formUnion(_ other: Options) {
    rawValue |= other.rawValue
  }
  
  public mutating func formIntersection(_ other: Options) {
    rawValue &= other.rawValue
  }
  
  public mutating func formSymmetricDifference(_ other: Options) {
    rawValue ^= other.rawValue
  }
  public func contains(_ value: Enum) -> Bool {
    return rawValue[value.rawValue]
  }
  public mutating func set(_ value: Enum, _ shouldInsert: Bool) {
    if shouldInsert {
      insert(value)
    } else {
      remove(value)
    }
  }
  public mutating func insert(_ value: Enum) {
    rawValue[value.rawValue] = true
  }
  public mutating func remove(_ value: Enum) {
    rawValue[value.rawValue] = false
  }
  public mutating func remove(_ value: Options) {
    rawValue &= ~value.rawValue
  }
}

// MARK:- Equatable
extension Options: Equatable {
  public static func ==(l: Options, r: Options) -> Bool {
    return l.rawValue == r.rawValue
  }
}
extension Options: Hashable {
  public func hash(into hasher: inout Hasher) {
    rawValue.hash(into: &hasher)
  }
}

// MARK:- Comparable
extension Options: Comparable {
  public static func < (lhs: Options, rhs: Options) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  public static func <= (lhs: Options, rhs: Options) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  public static func >= (lhs: Options, rhs: Options) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  public static func > (lhs: Options, rhs: Options) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

// MARK:- BinaryInteger
extension Options: BinaryInteger {
  public static func <<= <RHS>(lhs: inout Options, rhs: RHS) where RHS : BinaryInteger {
    lhs.rawValue <<= rhs
  }
  
  public static func >>= <RHS>(lhs: inout Options, rhs: RHS) where RHS : BinaryInteger {
    lhs.rawValue >>= rhs
  }
  
  public static prefix func ~ (x: Options) -> Options {
    return Options(~x.rawValue)
  }
  
  public typealias Words = RawValue.Words
  public static var isSigned: Bool {
    return RawValue.isSigned
  }
  
  public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
    if let rawValue = RawValue(exactly: source) {
      self.rawValue = rawValue
    } else {
      return nil
    }
  }
  public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
    rawValue = RawValue(truncatingIfNeeded: source)
  }
  public init<T>(clamping source: T) where T : BinaryInteger {
    rawValue = RawValue(clamping: source)
  }
  
  public init<T>(_ source: T) where T : BinaryFloatingPoint {
    rawValue = RawValue(source)
  }
  
  public init<T>(_ source: T) where T : BinaryInteger {
    rawValue = RawValue(source)
  }
  
  public var words: RawValue.Words {
    return rawValue.words
  }
  
  public var bitWidth: Int {
    return rawValue.bitWidth
  }
  
  public var trailingZeroBitCount: Int {
    return rawValue.trailingZeroBitCount
  }
  
  public static func / (lhs: Options, rhs: Options) -> Options {
    return Options(lhs.rawValue / rhs.rawValue)
  }
  
  public static func /= (lhs: inout Options, rhs: Options) {
    lhs.rawValue /= rhs.rawValue
  }
  
  public static func % (lhs: Options, rhs: Options) -> Options {
    return Options(lhs.rawValue % rhs.rawValue)
  }
  
  public static func %= (lhs: inout Options, rhs: Options) {
    lhs.rawValue %= rhs.rawValue
  }
  
  public static func &= (lhs: inout Options, rhs: Options) {
    lhs.rawValue &= rhs.rawValue
  }
  
  public static func |= (lhs: inout Options, rhs: Options) {
    lhs.rawValue |= rhs.rawValue
  }
  
  public static func ^= (lhs: inout Options, rhs: Options) {
    lhs.rawValue ^= rhs.rawValue
  }
}

// MARK:- ExpressibleByArrayLiteral
extension Options: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Enum
  public init(arrayLiteral elements: Enum...) {
    self.init(elements)
  }
}

// MARK:- ExpressibleByIntegerLiteral
extension Options: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: RawValue) {
    self.init(value)
  }
}

// MARK:- Numeric
extension Options: Numeric {
  public typealias Magnitude = RawValue.Magnitude
  public typealias IntegerLiteralType = Int
  public var magnitude: RawValue.Magnitude {
    return rawValue.magnitude
  }
  public init?<T>(exactly source: T) where T : BinaryInteger {
    rawValue = RawValue(source)
  }
  public init(integerLiteral value: Options.IntegerLiteralType) {
    rawValue = RawValue(value)
  }
  public static func *(lhs: Options, rhs: Options) -> Options {
    return Options(rawValue: lhs.rawValue * rhs.rawValue)
  }
  public static func *=(lhs: inout Options, rhs: Options) {
    lhs.rawValue *= rhs.rawValue
  }
  public static func +(lhs: Options, rhs: Options) -> Options {
    return Options(rawValue: lhs.rawValue + rhs.rawValue)
  }
  public static func +=(lhs: inout Options, rhs: Options) {
    lhs.rawValue += rhs.rawValue
  }
  public static func -(lhs: Options, rhs: Options) -> Options {
    return Options(rawValue: lhs.rawValue - rhs.rawValue)
  }
  public static func -=(lhs: inout Options, rhs: Options) {
    lhs.rawValue -= rhs.rawValue
  }
}

// MARK:- CustomStringConvertible
extension Options: CustomStringConvertible {
  public var description: String {
    var string = ""
    for i in 0..<Enum.count {
      if rawValue[i] {
        string += "1,"
      } else {
        string += "0,"
      }
    }
    string.removeLast()
    return string
  }
  public func description(withInit createEnum: (Enum.RawValue)->(Enum?)) -> String {
    var string = ""
    for i in 0..<Enum.count {
      let value = createEnum(Enum.RawValue(i))!
      string += "\n\(value): \(rawValue[i])"
    }
    if string.isEmpty {
      return "empty"
    } else {
      return string
    }
  }
}

