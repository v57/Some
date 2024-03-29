//
//  DispatchQueue.swift
//  Vijo server
//
//  Created by Димасик on 08/06/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation

// MARK: Dispatch Queue

/// run @block in main thread
public func mainThread(_ block: @escaping ()->()) {
  if Thread.current.isMainThread {
    block()
  } else {
    DispatchQueue.main.async(execute: block)
  }
}
public func mainThreadSync(_ block: @escaping ()throws->()) throws {
  if Thread.current.isMainThread {
    try block()
  } else {
    let semaphore = DispatchSemaphore(value: 0)
    var _error: Error?
    DispatchQueue.main.async {
      do {
        try block()
      } catch {
        _error = error
      }
      semaphore.signal()
    }
    semaphore.wait()
    if let error = _error {
      throw error
    }
  }
}

/// run @block in background thread
public func backgroundThread(_ block: @escaping ()->()) {
  DispatchQueue.global(qos: .background).async(execute: block)
}

extension Time {
  public func wait(_ block: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(self), execute: block)
  }
}

/// wait @time seconds, then run @execute in main thread
public func wait(_ time: Double, _ execute: @escaping ()->()) {
  DispatchQueue.main.wait(time, execute)
}
public func wait(_ time: Range<Double>, _ execute: @escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .random(in: time), execute: execute)
}

public func wait<T: AnyObject>(_ time: Double, weak object: T, _ path: ReferenceWritableKeyPath<T,Int>, _ execute: @escaping ()->()) {
  DispatchQueue.main.wait(time, weak: object, path, execute)
}
public func wait(_ time: Double, _ version: UnsafeMutablePointer<Int>, _ execute: @escaping ()->()) {
  DispatchQueue.main.wait(time, version, execute)
}

public extension DispatchQueue {
  static func ==(l: DispatchQueue, r: DispatchQueue) -> Bool {
    return l === r
  }
  func wait(_ time: Double, _ execute: @escaping ()->()) {
    asyncAfter(deadline: DispatchTime.now() + time, execute: execute)
  }
  func wait<T: AnyObject>(_ time: Double, weak object: T, _ path: ReferenceWritableKeyPath<T,Int>, _ execute: @escaping ()->()) {
    object[keyPath: path] += 1
    let v = object[keyPath: path]
    wait(time) { [weak object] in
      guard let object = object else { return }
      guard v == object[keyPath: path] else { return }
      execute()
    }
  }
  func wait(_ time: Double, _ version: UnsafeMutablePointer<Int>, _ execute: @escaping ()->()) {
    version.pointee += 1
    let v = version.pointee
    wait(time) {
      if v == version.pointee {
        execute()
      }
    }
  }
  
  func read<T>(using block: () throws -> (T)) rethrows -> T {
    try sync {
      try block()
    }
  }
  func read(execute: ()->()) {
    sync(execute: execute)
  }
  func syncWrite<T>(execute: () throws -> T) rethrows -> T {
    try sync(execute: execute)
  }
  func write(execute: @escaping ()->()) {
    async(flags: .barrier, execute: execute)
  }
  
  #if os(iOS) // DispatchQueue doesn't conforms to Hashable on Linux
  private static var nextOperations = [DispatchQueue: [()->()]]()
  /// Executes multiple callbacks on the next async event
  func next(_ execute: @escaping ()->()) {
    guard DispatchQueue.nextOperations.mutate(at: self, default: { [] }, mutate: {
      $0.append(execute)
    }).count == 1 else { return }
    self.async {
      DispatchQueue.nextOperations.removeValue(forKey: self)?.forEach { $0() }
    }
  }
  #endif
}

/// Class that allows to call multple waits and executes only the last one
public class Waiter {
  private var version = 0
  private var queue: DispatchQueue
  public init(queue: DispatchQueue = .main) {
    self.queue = queue
  }
  public func wait(_ time: Double, _ execute: @escaping ()->()) {
    queue.wait(time, weak: self, \.version, execute)
  }
  public func cancel() {
    version += 1
  }
  /// Repeats `execute` function in time interval.
  /// You can sefely use `[unowned self]` if waiter is only stores in self
  public func `repeat`(_ time: Double, _ execute: @escaping ()->()) {
    wait(time) { [weak self] in
      guard let self = self else { return }
      // storing current version, so you could cancel repeater inside execute function
      let version = self.version
      execute()
      if self.version == version {
        self.repeat(time, execute)
      }
    }
  }
  /// Repeats `execute` function in time interval.
  /// You can sefely use `[unowned self]` if waiter is only stores in self
  public func `repeat`(_ time: Double, _ count: Int, _ execute: @escaping ()->()) {
    guard count >= 0 else { return }
    wait(time) { [weak self] in
      guard let self = self else { return }
      // storing current version, so you could cancel repeater inside execute function
      let version = self.version
      execute()
      if self.version == version {
        self.repeat(time, count - 1, execute)
      }
    }
  }
  public func external() -> External {
    External(waiter: self)
  }
  public class WithStatus: Waiter {
    public var isWaiting = false
    override var version: Int {
      didSet {
        isWaiting = false
      }
    }
    public override func wait(_ time: Double, _ execute: @escaping () -> ()) {
      version += 1
      let v = version
      isWaiting = true
      queue.wait(time) { [weak self] in
        guard let self = self else { return }
        guard v == self.version else { return }
        self.isWaiting = false
        execute()
      }
    }
  }
  public struct External {
    public weak var waiter: Waiter?
    private let version: Int
    public init(waiter: Waiter) {
      waiter.version += 1
      self.waiter = waiter
      self.version = waiter.version
    }
    public func run(_ action: ()->()) {
      guard let waiter = waiter else { return }
      guard waiter.version == version else { return }
      action()
    }
  }
}

public class Throttle {
  public let queue: DispatchQueue
  public var time: Double
  public private(set) var operations = [()->(Bool)]()
  public private(set) var isWaiting = false
  private var selfOwned: Throttle?
  private var isIdle: Bool { !isWaiting }
  public init(_ time: Double, on queue: DispatchQueue = .main) {
    self.time = time
    self.queue = queue
  }
  public func run(_ operation: @escaping ()->()) {
    if isIdle {
      operation()
      wait()
    } else {
      operations.append {
        operation()
        return true
      }
    }
  }
  public func run(_ object: AnyObject, _ operation: @escaping ()->()) {
    if isIdle {
      operation()
      wait()
    } else {
      operations.append { [weak object] in
        guard object != nil else { return false }
        operation()
        return true
      }
    }
  }
  public func skippableRun(_ object: AnyObject, _ operation: @escaping ()->(Bool)) {
    if isIdle {
      if operation() {
        wait()
      }
    } else {
      operations.append { [weak object] in
        guard object != nil else { return false }
        return operation()
      }
    }
  }
  public func autorelease() {
    guard operations.count > 0 else { return }
    selfOwned = self
  }
  private func wait() {
    isWaiting = true
    queue.wait(time) { [weak self] in
      guard let self = self else { return }
      guard self.isWaiting else { return }
      self.isWaiting = false
      self.next()
    }
  }
  private func next() {
    guard operations.count > 0 else {
      selfOwned = nil
      return }
    let shouldWait = operations.removeFirst()()
    if shouldWait {
      wait()
    } else {
      next()
    }
  }
  public class Pausable: Throttle {
    var isRunning = true
    override var isIdle: Bool { isRunning && !isWaiting }
    public func resume() {
      guard !isRunning else { return }
      guard !isWaiting else { return }
      isRunning = true
      next()
    }
    public func pause() {
      guard isRunning else { return }
      isRunning = false
      isWaiting = false
    }
    override func next() {
      guard isRunning else { return }
      guard !isWaiting else { return }
      super.next()
    }
  }
  public class SafePausable: Throttle {
    private var links = 0 {
      didSet {
        if links == 0 {
          _resume()
        } else if links == 1 && oldValue == 0 {
          _pause()
        }
      }
    }
    private var isRunning = true
    override var isIdle: Bool { isRunning && !isWaiting }
    public func pause() -> Link {
      let link = Link()
      link.parent = self
      return link
    }
    private func _resume() {
      guard !isRunning else { return }
      guard !isWaiting else { return }
      isRunning = true
      next()
    }
    private func _pause() {
      guard isRunning else { return }
      isRunning = false
      isWaiting = false
    }
    override func next() {
      guard isRunning else { return }
      guard !isWaiting else { return }
      super.next()
    }
    public class Link {
      public weak var parent: SafePausable? {
        didSet {
          parent?.links += 1
          oldValue?.links -= 1
        }
      }
      public init() {}
      public func attach(_ parent: SafePausable) {
        self.parent = parent
      }
      public func detach() {
        parent = nil
      }
      deinit {
        parent = nil
      }
    }
  }
  public class Skip {
    public private(set) var lastOperation: (()->())?
    public let queue: DispatchQueue
    public var time: Double
    public private(set) var isWaiting = false
    public init(_ time: Double, on queue: DispatchQueue = .main) {
      self.time = time
      self.queue = queue
    }
    public func run(_ operation: @escaping ()->()) {
      if isWaiting {
        lastOperation = operation
      } else {
        operation()
        isWaiting = true
        queue.wait(time) { [weak self] in
          guard let self = self else { return }
          self.isWaiting = false
          if let lastOperation = self.lastOperation {
            self.lastOperation = nil
            self.run(lastOperation)
          }
        }
      }
    }
    public func cancel() {
      lastOperation = nil
    }
  }
}

/// run @block in new thread
public func newThread(_ block: @escaping ()->()) {
  let queue = DispatchQueue.global(qos: .default)
  queue.async(execute: block)
}

/// block current thread untill unblock() returns false
public func blockThread(untill unblock: ()->Bool) {
  while !unblock() {
    sleep(1)
  }
}

// MARK: - Locking
public func locked(_ mutex: UnsafeMutablePointer<pthread_mutex_t>,f: ()->()) {
  pthread_mutex_lock(mutex)
  f()
  pthread_mutex_unlock(mutex)
}

public func pthread(block: @escaping ()->()) {
  if #available(OSX 10.12, *) {
    Thread(block: block).start()
  } else {
    OperationQueue().addOperation(block)
  }
}
