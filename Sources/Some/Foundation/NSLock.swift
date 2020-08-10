//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/25/20.
//

import Foundation

extension NSLock {
  @discardableResult
  public func lock<T>(_ execute: () throws -> (T)) rethrows -> T {
    lock()
    defer { unlock() }
    return try execute()
  }
}

// MARK:- SomeThread
public var thread = SomeThread(name: "somethread")
open class SomeThread {
  private let queue: DispatchQueue
  public var locker: NSLock
  public init(name: String) {
    queue = DispatchQueue(label: name, attributes: .concurrent)
    locker = NSLock()
  }
  
  open func async(block: @escaping ()->()) {
    queue.async {
      self.locker.lock()
      block()
      self.locker.unlock()
    }
  }
  
  open func named(_ name: String, block: @escaping ()->()) {
    DispatchQueue(label: name).async(execute: block)
  }
  
  open func main(block: @escaping ()->()) {
    DispatchQueue.main.async(execute: block)
  }
  
  open func background(block: @escaping ()->()) {
    DispatchQueue.global(qos: .background).async(execute: block)
  }
  
  open func new(block: @escaping ()->()) {
    DispatchQueue.global(qos: .default).async(execute: block)
  }
  
  open func readWrite(execute: ()->()) {
    queue.sync(execute: execute)
  }
  open func write(execute: @escaping ()->()) {
    queue.async(flags: .barrier, execute: execute)
  }
  open func lock() {
    locker.lock()
  }
  open func unlock() {
    locker.unlock()
  }
  @discardableResult
  open func lock<T>(_ block: ()throws->(T)) rethrows -> T {
    lock()
    defer { unlock() }
    return try block()
  }
  
  // deadlock debugger
  
  // open func lock(file: String = #file, function: String = #function, line: Int = #line) {
  //   print("locking thread")
  //   locker.lock()
  //   print("\(file) \(function) \(line)")
  //   print("thread locked")
  // }
  // open func unlock() {
  //   locker.unlock()
  //   print("thread unlocked")
  // }
  // @discardableResult
  // open func lock<T>(file: String = #file, function: String = #function, line: Int = #line, _ block: ()throws->(T)) rethrows -> T {
  //   print("locking thread")
  //   locker.lock()
  //   print("\(file) \(function) \(line)")
  //   print("thread locked")
  //   defer {
  //     locker.unlock()
  //     print("thread unlocked")
  //   }
  //   return try block()
  // }
}
