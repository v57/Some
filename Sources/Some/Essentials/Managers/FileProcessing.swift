//
//  FileProcessing.swift
//  SomeFunctions
//
//  Created by Димасик on 4/20/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import Foundation

class FileQueue: OperationQueue {
  override init() {
    super.init()
    name = "File Queue"
    maxConcurrentOperationCount = 1
  }
}
public let fileQueue: OperationQueue = FileQueue()
private var fileOperations = [FileURL: FileURLActions]()
private var aliases = [FileURL: FileURL]()
private let locker = NSLock()

public extension FileURL {
  func prepare() {
    var action = fileOperations[self]
    if action == nil {
      action = FileURLActions(url: self)
      fileOperations[self] = action
    }
    action!.prepare()
  }
  func run(operation: @escaping (FileURL)->()) {
    var action = fileOperations[self]
    if action == nil {
      action = FileURLActions(url: self)
      fileOperations[self] = action
    }
    action!.run(operation: operation)
  }
  func whenReady(action: @escaping ()->()) {
    if let a = fileOperations[self] {
      a.whenReady(action: action)
    } else if !exists {
      let a = FileURLActions(url: self)
      a.subscriber.reset()
      fileOperations[self] = a
      a.whenReady(action: action)
    } else {
      action()
    }
  }
  
  var alias: FileURL {
    locker.lock()
    let alias = aliases[self]
    locker.unlock()
    return alias ?? self
  }
  func alias(with url: FileURL) {
    //    let name = "\(url.directory.fileName)/\(url.fileName)"
    locker.lock()
    //    print("[\(name)] aliasing \(self)\n with \(url)")
    if let old = fileOperations[self] {
      //      if old.subscriber.isCompleted {
      //        print("[\(name)] old is ready to alias")
      //      } else {
      //        print("[\(name)] old is not ready to alias")
      //      }
      //      if !systemExists {
      //        print("[\(name)] FILE NOT EXISTS")
      //      }
      //      print("[\(name)] updating file actions")
      fileOperations[url] = old
      old.url = url
      locker.unlock()
      old.run { url in
        //        if !self.systemExists {
        //          print("[\(name)] FILE STILL NOT EXISTS !!!!!")
        //        }
        //        print("[\(name)] aliasing directory.create")
        url.directory.create(subdirectories: true)
        //        print("[\(name)] aliasing move")
        self.move(to: url)
        //        print("[\(name)] aliasing completed")
      }
    } else {
      //      print("[\(name)] aliasing creating file actions")
      let new = FileURLActions(url: url)
      fileOperations[self] = new
      fileOperations[url] = new
      locker.unlock()
      new.run { url in
        //        print("[\(name)] aliasing directory.create")
        url.directory.create(subdirectories: true)
        //        print("[\(name)] aliasing move")
        self.move(to: url)
        //        print("[\(name)] aliasing completed")
      }
    }
  }
}
class FileURLActions {
  var url: FileURL
  let subscriber = SafeCompletionSubscribers()
  var actions = SafeArray<(FileURL)->()>()
  init(url: FileURL) {
    self.url = url
    subscriber.isCompleted = true
  }
  func prepare() {
    guard subscriber.isCompleted else { return }
    url.set(exists: true)
    subscriber.reset()
    fileQueue.addOperation {
      self.url.directory.create(subdirectories: true)
      self.runAll()
    }
  }
  func run(operation: @escaping (FileURL)->()) {
    actions.append(operation)
    next()
  }
  private func next() {
    locker.lock()
    let isCompleted = subscriber.isCompleted
    locker.unlock()
    guard isCompleted else { return }
    guard !actions.isEmpty else { return }
    subscriber.reset()
    fileQueue.addOperation {
      self.runAll()
    }
  }
  private func runAll() {
    while !actions.isEmpty {
      let action = actions.removeFirst()
      locker.lock()
      let url = self.url
      locker.unlock()
      action(url)
    }
    subscriber.trigger()
  }
  func whenReady(action: @escaping ()->()) {
    subscriber.subscribe(action: action)
  }
}
private let broadcasterLock = NSLock()
open class SafeCompletionSubscribers {
  public var handlers = [()->()]()
  public var isCompleted = false
  
  public init() {}
  public func subscribe(action: @escaping ()->()) {
    broadcasterLock.lock()
    if isCompleted {
      broadcasterLock.unlock()
      action()
    } else {
      handlers.append(action)
      broadcasterLock.unlock()
    }
  }
  public func reset() {
    broadcasterLock.lock()
    defer { broadcasterLock.unlock() }
    isCompleted = false
  }
  public func trigger() {
    broadcasterLock.lock()
    guard !isCompleted else {
      broadcasterLock.unlock()
      return }
    isCompleted = true
    let handlers = self.handlers
    self.handlers.removeAll()
    broadcasterLock.unlock()
    handlers.forEach { $0() }
  }
}
