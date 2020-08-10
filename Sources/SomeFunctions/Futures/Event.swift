//
//  Event.swift
//  SomeFunctions
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

//public typealias SomeEvent = Event
//open class Event<T> {
//  public var subscribers = [EventSubscriber<T>]()
////  public var subscribers = OptimizedArray<(T)->()>.none
//  public var isEmpty: Bool { subscribers.isEmpty }
//  public init() {
//    
//  }
//  public func append(_ subscriber: EventSubscriber<T>) -> EventSubscriber<T> {
//    subscribers.append(subscriber)
//    return subscriber
//  }
//  @discardableResult
//  public func subscribe(_ event: Event<T>) -> EventSubscriber<T> {
//    return append(EventSubscriber(subscription: self) { event.send($0) })
//  }
//  @discardableResult
//  public func event(_ action: @escaping (T)->()) -> EventSubscriber<T> {
//    return append(EventSubscriber(subscription: self, action: action))
//  }
//  @discardableResult
//  public func event<C: AnyObject>(_ object: C, _ action: @escaping (C,T)->()) -> EventSubscriber<T> {
//    return event { [weak object] result in
//      guard let object = object else { return }
//      action(object, result)
//    }
//  }
//  public func send(_ content: T) {
//    subscribers = subscribers.filter { $0.send(content) }
//  }
//}
//extension Event where T == Void {
//  public func send() {
//    send(())
//  }
//}
//public class EventSubscriber<T> {
//  public var linked: WeakArray<AnyObject>?
//  public var action: (T)->()
//  public unowned var subscription: Event<T>
//  
//  public init(subscription: Event<T>, action: @escaping (T)->()) {
//    self.subscription = subscription
//    self.action = action
//  }
//  public func send(_ content: T) -> Bool {
//    if let array = linked, array.count == 0 {
//      return false
//    }
//    action(content)
//    return true
//  }
//  public func remove(_ value: AnyObject) {
//    guard let array = linked else { return }
//    array.removeObject(value)
//  }
//  @discardableResult
//  public func link(_ value: AnyObject) -> Self {
//    if linked == nil {
//      linked = WeakArray()
//    }
//    linked!.append(value)
//    return self
//  }
//}


enum OptimizedArray<Element> {
  case none
  case value(Element)
  case array([Element])
  init() {
    self = .none
  }
  mutating func append(_ value: Element) {
    switch self {
    case .none:
      self = .value(value)
    case .value(let first):
      self = .array([first, value])
    case .array(var array):
      array.append(value)
      self = .array(array)
    }
  }
}
extension OptimizedArray: RangeReplaceableCollection {
  typealias Index = Int
  //  typealias SubSequence
  var startIndex: Int {
    return 0
  }
  var endIndex: Int {
    switch self {
    case .none: return 0
    case .value: return 1
    case .array(let array): return array.endIndex
    }
  }
  subscript(position: Int) -> Element {
    switch self {
    case .none: fatalError("Out of bounds")
    case .value(let value):
      guard position == 0 else { fatalError("Out of bounds") }
      return value
    case .array(let array):
      return array[position]
    }
  }
  func forEach(_ body: (Element) throws -> Void) rethrows {
    switch self {
    case .none: break
    case .value(let value): try body(value)
    case .array(let array): try array.forEach(body)
    }
  }
  func index(after i: Int) -> Int {
    return i+1
  }
}
