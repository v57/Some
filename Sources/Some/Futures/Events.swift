//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 27/10/2020.
//

import Foundation

public struct ObjectEvent<T: AnyObject> {
  public var parent: T
  public init(_ parent: T) {
    self.parent = parent
  }
}
/// A type that has reactive extensions.
public protocol ObjectEventProtocol: AnyObject {
  associatedtype EventBase: AnyObject
  var event: ObjectEvent<EventBase> { get }
}
public extension ObjectEventProtocol {
  var event: ObjectEvent<Self> { ObjectEvent(self) }
}

#if !os(Linux)
extension NSObject: ObjectEventProtocol { }
#endif
