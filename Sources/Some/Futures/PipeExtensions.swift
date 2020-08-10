//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 24/10/2019.
//

import Foundation

infix operator ~: MultiplicationPrecedence
public func &<T, O: AnyObject>(l: P<T>, r: O) -> PipeLinker<T,O> {
  PipeLinker(object: r, pipe: l)
}
public func &<T>(l: P<T>, r: @escaping (T)->()) -> S {
  l.next(r)
}
public func &<T>(l: P<T>, r: P<T>) -> P<T> {
  r.add(to: l)
}
public func &<T, O: AnyObject>(l: P<T>, r: ObjectPath<O, T>) -> S {
  l.add(r)
}
// public func ~<O: AnyObject>(l: P<Void>, r: ObjectPath<O, Bool>) {
//   l.connect(TogglePathConnection(r.object, r.path))
// }
//
public struct PipeLinker<T, O: AnyObject> {
  public let object: O
  public let pipe: P<T>
  public var weakPipe: P<(O,T)> {
    pipe.weak(object)
  }
  public func path<Value>(_ path: ReferenceWritableKeyPath<O, Value>) -> ObjectPath<O, Value> {
    ObjectPath(object: object, path: path)
  }
  public func next(_ action: @escaping (O,T)->()) -> S {
    weakPipe.next(action)
  }
}
public extension PipeLinker {
  static func &(l: PipeLinker, r: ReferenceWritableKeyPath<O,T>) -> S {
    l.pipe.add(l.path(r))
  }
  static func &(l: PipeLinker, r: @escaping (O)->(T)->()) -> S {
    l.weakPipe.next { r($0.0)($0.1) }
  }
  static func &(l: PipeLinker, r: @escaping (O, T)->()) -> S {
    l.next(r)
  }
}
public func &<O, A, B>(l: PipeLinker<(A, B), O>, r: @escaping (O)->(A, B)->()) -> S {
  l.weakPipe.next { (o, v) in
    r(o)(v.0, v.1)
  }
}
public func &<O, A, B>(l: PipeLinker<(A, B), O>, r: @escaping (O)->(A, B)->()) where O: PipeStorage {
  l.weakPipe.next { (o, v) in
    r(o)(v.0, v.1)
  }.store(in: l.object)
}
public extension PipeLinker where O: PipeStorage {
  static func &(l: PipeLinker, r: @escaping (O)->(T)->()) {
    l.weakPipe.next { r($0.0)($0.1) }.store(in: l.object)
  }
  static func &(l: PipeLinker, r: @escaping (O, T)->()) {
    l.next(r).store(in: l.object)
  }
}
public extension PipeLinker where T == Void, O: PipeStorage {
  static func &(l: PipeLinker, r: @escaping (O)->()->()) {
    l.weakPipe.input0().next { r($0)() }.store(in: l.object)
  }
  static func &(l: PipeLinker, r: @escaping (O)->()) {
    l.weakPipe.input0().next(r).store(in: l.object)
  }
}
public extension PipeLinker where T == Void {
  static func &(l: PipeLinker, r: @escaping (O)->()->()) -> S {
    l.weakPipe.input0().next { r($0)() }
  }
  static func &(l: PipeLinker, r: @escaping (O)->()) -> S {
    l.weakPipe.input0().next(r)
  }
}
//
public struct ObjectPath<Root: AnyObject, Value>: PipeReceiver {
  public typealias Input = Value
  public let object: Root
  public let path: ReferenceWritableKeyPath<Root, Value>
  public func receivedInput(_ value: Value) {
    object[keyPath: path] = value
  }
}

public extension P {
  func send<First,Second>(_ first: First, _ second: Second) where (First,Second) == Input {
    send((first, second))
  }
  // func toggle<Root: AnyObject>(_ object: Root, _ path: WritableKeyPath<Root, Bool>) {
  //   connect(TogglePathConnection(object, path))
  // }
}
