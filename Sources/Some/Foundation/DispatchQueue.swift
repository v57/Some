//
//  DispatchQueue.swift
//  faggot-server
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
  public func external() -> External {
    External(waiter: self)
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

// MARK:- Locking
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
