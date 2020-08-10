//
//  Subscription.swift
//  EthereumTests
//
//  Created by Dmitry on 31/01/2019.
//  Copyright © 2019 Bankex Foundation. All rights reserved.
//

import Foundation

extension Array {
  public func first<T: Comparable>(_ path: KeyPath<Element,T>, _ value: T) -> Element? {
    return first { $0[keyPath: path] == value }
  }
}

public protocol ListenerProtocol: class {
  associatedtype Result
  typealias Sub = Subscription<Self>
  
  //    var isSending: Bool { get set }
  //    var isRunning: Bool { get set }
  var counter: Int { get set }
  var subscribers: Set<Subscription<Self>> { get set }
  var filters: [(Result) -> Bool] { get }
  
  func subscribe(_ subscription: Subscription<Self>)
  func unsubscribe(_ subscription: Subscription<Self>)
  func resume()
  func pause()
  func trigger()
  func process(error: Error)
}
//public extension ListenerProtocol {
//    public var filters: [(Result) -> Bool] { return [] }
//    public func subscribe(_ subscription: Sub) {
//        lock.lock()
//        defer { lock.unlock() }
//        subscription.listener = self
//        subscribers.insert(subscription)
//        if subscribers.count == 1 {
//            assert(!isRunning)
//            guard !isSending else { return }
//            resume()
//        }
//    }
//    public func subscribe() -> Sub {
//        let subscription = Sub()
//        subscribe(subscription)
//        return subscription
//    }
//    public func unsubscribe(_ subscription: Sub) {
//        lock.lock()
//        defer { lock.unlock() }
//        guard subscribers.contains(subscription) else { return }
//        subscribers.remove(subscription)
//
//        if subscribers.count == 0 {
//            assert(isRunning)
//            isRunning = false
//            pause()
//        }
//    }
//    public func done(_ result: FutureResult<Result>) {
//        lock.lock()
//        defer { lock.unlock() }
//        assert(isSending)
//        isSending = false
//        switch result {
//        case .success(let event):
//            if filters.contains(where: { $0(event) }) {
//                trigger()
//                subscribers.forEach { $0.event(event) }
//            }
//        case .failure(let error):
//            process(error: error)
//        }
//        guard isRunning else { return }
//        resume()
//    }
//    public func process(error: Error) {}
//}

final public class TimerTrigger: Trigger {
  public var interval: Double
  public init(_ interval: Double) {
    self.interval = interval
  }
  public override func resume() { // calls locked
    send()
  }
  func send() { // calls locked
    isSending = true
    DispatchQueue.some.asyncAfter(deadline: .now() + interval, execute: waited)
  }
  func waited() { // calls unlocked
    trigger()
    lock.lock()
    if counter > 0 {
      send()
    }
    lock.unlock()
  }
}

private let lock = NSLock()

open class Trigger {
  public var triggerSubscribers = [ObjectIdentifier: ()->()]()
  public var counter = 0 { // calls locked
    didSet {
      if oldValue == 0 {
        guard !isSending else { return }
        resume()
      } else if counter == 0 {
        pause()
      }
    }
  }
  public var isSending = false
  public func subscribe(id: ObjectIdentifier, trigger: @escaping ()->()) {
    lock.lock()
    defer { lock.unlock() }
    
    guard triggerSubscribers[id] == nil else { return }
    triggerSubscribers[id] = trigger
    counter += 1
  }
  public func subscribe(id: AnyObject, trigger: @escaping ()->()) {
    let id = ObjectIdentifier(id)
    subscribe(id: id, trigger: trigger)
  }
  public func unsubscribe(id: ObjectIdentifier) {
    lock.lock()
    defer { lock.unlock() }
    guard triggerSubscribers[id] != nil else { return }
    triggerSubscribers[id] = nil
    counter -= 1
  }
  public func unsubscribe(id: AnyObject) {
    let id = ObjectIdentifier(id)
    unsubscribe(id: id)
  }
  
  public func trigger() { // calls unlocked
    lock.lock()
    isSending = false
    let values = triggerSubscribers.values
    lock.unlock()
    values.forEach { $0() }
  }
  open func resume() {} // calls locked
  open func pause() {} // calls locked
  public static func timer(_ time: Double) -> TimerTrigger {
    return TimerTrigger(time)
  }
}

final
public class EventListener<Result>: Trigger, ListenerProtocol {
  public var subscribers = Set<Sub>()
  
  public var request: (() -> Future<Result>)
  public var filters = [(Result) -> Bool]()
  public var trigger: Trigger
  
  public init(trigger: Trigger, call request: @escaping () -> Future<Result>) {
    self.trigger = trigger
    self.request = request
  }
  public override func resume() {
    let trigger = self.trigger
    let id = ObjectIdentifier(self)
    isSending = true
    lock.unlock()
    defer { lock.lock() }
    trigger.subscribe(id: id) { [weak self] in
      if let self = self {
        self.event(trigger: trigger)
      } else {
        trigger.unsubscribe(id: id)
      }
    }
  }
  public override func pause() {
    
  }
  public func filter(_ filter: @escaping (Result) -> Bool) -> Self { // calls unlocked
    lock.lock()
    defer { lock.unlock() }
    self.filters.append(filter)
    return self
  }
  
  public func event(trigger: Trigger) { // calls unlocked
    trigger.unsubscribe(id: self)
    request().pipe(done)
  }
  
  public func subscribe(_ subscription: Sub) { // calls unlocked
    lock.lock()
    defer { lock.unlock() }
    subscription.listener = self
    subscribers.insert(subscription)
    counter += 1
  }
  public func subscribe() -> Sub { // calls unlocked
    let subscription = Sub()
    subscribe(subscription)
    return subscription
  }
  public func unsubscribe(_ subscription: Sub) { // calls unlocked
    lock.lock()
    defer { lock.unlock() }
    guard subscribers.contains(subscription) else { return }
    subscribers.remove(subscription)
    counter -= 1
  }
  public func done(_ result: FutureResult<Result>) {
    lock.lock()
    defer { lock.unlock() }
    assert(isSending)
    isSending = false
    switch result {
    case .success(let event):
      if filters.isEmpty || filters.contains(where: { $0(event) }) {
        lock.unlocked(trigger)
        subscribers.forEach { $0.event(event) }
      }
    case .failure(let error):
      process(error: error)
    }
    guard counter > 0 else { return }
    resume()
  }
  public func process(error: Error) {}
}

open class Subscription<Listener: ListenerProtocol>: Hashable {
  public typealias Result = Listener.Result
  
  public weak var listener: Listener?
  public var callback: ((Result)->())?
  
  // Events
  open func subscribed() {}
  open func unsubscribed() {}
  
  
  open func event(_ event: Result) {
    callback?(event)
  }
  public func onEvent(_ callback: @escaping (Result)->()) -> Self {
    self.callback = callback
    return self
  }
  
  public func first<T>(where predicate: @escaping (Result)->(T?)) -> Future<T> {
    let future = Future<T>()
    callback = { [weak self] result in
      guard let self = self else { return }
      guard let result = predicate(result) else { return }
      future.success(result)
      self.unsubscribe()
    }
    return future
  }
  
  // Controls
  open func subscribe() {}
  open func unsubscribe() {}
  
  public static func == (l: Subscription, r: Subscription) -> Bool {
    return l === r
  }
  open func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
}

private extension NSLock {
  func unlocked(_ execute: ()->()) {
    unlock()
    execute()
    lock()
  }
}
