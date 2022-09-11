//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Foundation

public protocol EmptyInit {
  init()
}

public protocol Id: ComparsionValue&Hashable {
  associatedtype IdType: Comparable&Hashable
  var id: IdType { get }
}
extension Id {
  public var _valueToCompare: IdType { id }
  public func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }
}
public protocol HashableClass: AnyObject, Id {}
extension HashableClass {
  public var id: ObjectIdentifier { ObjectIdentifier(self) }
}


public protocol MutableId: AnyObject, Id {
  override var id: IdType { get set }
}

public protocol ComparsionValue: Comparable {
  associatedtype ValueToCompare: Comparable
  var _valueToCompare: ValueToCompare { get }
}
public extension ComparsionValue {
  static func == (l: Self, r: Self) -> Bool {
    l._valueToCompare == r._valueToCompare
  }
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs._valueToCompare < rhs._valueToCompare
  }
}
