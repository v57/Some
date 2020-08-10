//
//  Future.swift
//  web3swift
//
//  Created by Dmitry on 1/14/19.
//  Copyright © 2019 Bankex Foundation. All rights reserved.
//

import Foundation

//public struct FutureOptions: OptionSet {
//    public let rawValue: Int
//    public init(rawValue: Int) { self.rawValue = rawValue }
//    static let isCompleted = FutureOptions(rawValue: 0b1)
//    static let isRunning = FutureOptions(rawValue: 0b10)
//    static let isCancellable = FutureOptions(rawValue: 0b100)
//    static let isCancelled = FutureOptions(rawValue: 0b1000)
//    static let `default` = FutureOptions(rawValue: 0)
//}

func when<T>(fulfilled promises: [Future<T>]) -> Future<[T]> {
  return Future<T>.group(promises)
}
public func group<T>(_ futures: [Future<T>]) -> Future<[T]> {
  return Future<T>.group(futures)
}
extension Future {
  public static func groupSkipErrors<T>(_ futures: [Future<T>]) -> Future<[T]> {
    let future = Future<[T]>()
    if futures.count == 0 {
      future.success([])
    } else {
      var array = [T]()
      for promise in futures {
        promise.pipe { value in
          switch value {
          case .success(let value):
            array.append(value)
            if array.count == futures.count {
              future.success(array)
            }
          case .failure:
            break
          }
        }
      }
    }
    return future
  }
  public static func group<T>(_ futures: [Future<T>]) -> Future<[T]> {
    let future = Future<[T]>()
    if futures.count == 0 {
      future.success([])
    } else {
      var array = [T]()
      var failed = false
      for promise in futures {
        promise.pipe { value in
          guard !failed else { return }
          switch value {
          case .success(let value):
            array.append(value)
            if array.count == futures.count {
              future.success(array)
            }
          case .failure(let error):
            failed = true
            future.fail(error)
          }
        }
      }
    }
    return future
  }
  public static func value(_ value: T) -> Future<T> {
    return Future<T>(value: value)
  }
  public static func pending() -> (Future<T>,Future<T>) {
    let future = Future<T>()
    return (future,future)
  }
  public func fulfill(_ value: T) {
    success(value)
  }
  public func reject(_ error: Error) {
    fail(error)
  }
  @discardableResult
  public func done(on queue: DispatchQueue = .future, _ callback: @escaping (T) throws -> ()) -> Self {
    append(pipe: ResultPipe<T>.Async(on: queue, callback))
    return self
  }
  @discardableResult
  public func `catch`(on queue: DispatchQueue = .future, _ callback: @escaping (Error) throws -> ()) -> Self {
    append(pipe: ErrorPipe<T>.Async(on: queue, callback))
    return self
  }
  public func map<U>(on queue: DispatchQueue, _ transform: @escaping (T) throws -> (U)) -> Future<U> {
    let future = Future<U>()
    pipe(on: queue) { result in
      switch result {
      case .success(let value):
        try future.success(transform(value))
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  public func map<U>(operationQueue queue: OperationQueue, _ transform: @escaping (T) throws -> (U)) -> Future<U> {
    let future = Future<U>()
    pipe(on: queue) { result in
      switch result {
      case .success(let value):
        try future.success(transform(value))
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  public func then<U>(on queue: DispatchQueue, _ makeFuture: @escaping (T) throws -> (Future<U>)) -> Future<U> {
    let future = Future<U>()
    pipe(on: queue) { value in
      switch value {
      case .success(let value):
        let future2 = try makeFuture(value)
        future2.pipe(future.resolve)
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
}

public enum FutureError: Error {
  case nilValue
}

private let lock = NSLock()
public extension DispatchQueue {
  static var future: DispatchQueue = .main
}

extension Future where T == Void {
  public static var success: Future<T> {
    return Future(value: ())
  }
  public func success() {
    success(())
  }
}

public class Future<T> {
  public static func success(_ value: T) -> Future<T> {
    return Future(value: value)
  }
  public static func failed(_ error: Error) -> Future<T> {
    return Future(error: error)
  }
  public var value: T! {
    lock.lock()
    defer { lock.unlock() }
    return result?.value
  }
  public var error: Error! {
    lock.lock()
    defer { lock.unlock() }
    return result?.error
  }
  public private(set) var result: FutureResult<T>?
  //    var options: FutureOptions = .default
  fileprivate var pipes = [_Pipe<T>]()
  public var pipesCount: Int { pipes.count }
  public var progress: Progress?
  
  public init() {
    
  }
  public init(error: Error) {
    self.result = .failure(error)
  }
  public init(value: T) {
    self.result = .success(value)
  }
  
  public var `do`: P<T> {
    let pipe = Pipes.SingleResult<T>()
    success { [weak pipe] in
      pipe?.send($0)
      pipe?.close()
    }
    return pipe
  }
  public var `catch`: P<Error> {
    let pipe = P<Error>()
    fail {
      pipe.send($0)
    }
    return pipe
  }
  @discardableResult
  public func pipe(_ callback: @escaping (FutureResult<T>) throws -> ()) -> Self {
    append(pipe: AnyPipe<T>(callback))
    return self
  }
  @discardableResult
  public func pipe(on queue: DispatchQueue, _ callback: @escaping (FutureResult<T>) throws -> ()) -> Self {
    append(pipe: AnyPipe<T>.Async(on: queue, callback))
    return self
  }
  @discardableResult
  public func pipe(on queue: OperationQueue, _ callback: @escaping (FutureResult<T>) throws -> ()) -> Self {
    append(pipe: AnyPipe<T>.Queue(on: queue, callback))
    return self
  }
  @discardableResult
  public func success(_ callback: @escaping (T) throws -> ()) -> Self {
    append(pipe: ResultPipe<T>.Async(on: .future, callback))
    return self
  }
  @discardableResult
  public func weakSuccess<U: AnyObject>(_ object: U, _ callback: @escaping (U, T) throws -> ()) -> Self {
    success { [weak object] value in
      guard let object = object else { return }
      try callback(object, value)
    }
    return self
  }
  @discardableResult
  public func fail(_ callback: @escaping (Error) throws -> ()) -> Self {
    append(pipe: ErrorPipe<T>.Async(on: .future, callback))
    return self
  }
  fileprivate func append(pipe: _Pipe<T>) {
    lock.lock()
    if let value = result {
      lock.unlock()
      pipe.resolve(value)
    } else {
      pipes.append(pipe)
      lock.unlock()
    }
  }
  public func any() -> Future<Any> {
    let future = Future<Any>()
    pipe { result in
      switch result {
      case .success(let value):
        future.success(value)
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  public func void() -> Future<Void> {
    let future = Future<Void>()
    pipe { result in
      switch result {
      case .success:
        future.success(())
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  @discardableResult
  public func attach(_ future: Future<T>) -> Self {
    guard future.result == nil else { return self }
    pipe { result in
      future.resolve(result)
    }
    return self
  }
  public func pipe() -> SingleResult<T> {
    let pipe = SingleResult<T>()
    success(pipe.send)
    return pipe
  }
  @discardableResult
  public func pipe(_ pipe: P<T>) -> Self {
    success(pipe.send)
  }
  public func mapNil<U>(_ transform: @escaping (T) throws -> (U?)) -> Future<U> {
    let future = Future<U>()
    pipe { result in
      switch result {
      case .success(let value):
        if let value = try transform(value) {
          future.success(value)
        } else {
          future.fail(FutureError.nilValue)
        }
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  public func mapError(_ transform: @escaping (Error) -> (Error)) -> Future<T> {
    let future = Future<T>()
    pipe { result in
      switch result {
      case .success(let value):
        future.success(value)
      case .failure(let error):
        future.fail(transform(error))
      }
    }
    return future
  }
  public func map<U>(_ keyPath: KeyPath<T,U>) -> Future<U> {
    return map { $0[keyPath: keyPath] }
  }
  public func mapNullable<U>(_ keyPath: KeyPath<T,U>) -> Future<U?> {
    return map { $0[keyPath: keyPath] }
  }
  public func map<U>(_ transform: @escaping (T) throws -> (U)) -> Future<U> {
    let future = Future<U>()
    pipe { result in
      switch result {
      case .success(let value):
        do {
          try future.success(transform(value))
        } catch {
          future.fail(error)
        }
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  public func then<U>(_ makeFuture: @escaping (T) throws -> (Future<U>)) -> Future<U> {
    let future = Future<U>()
    pipe { value in
      switch value {
      case .success(let value):
        let future2 = try makeFuture(value)
        future2.pipe(future.resolve)
      case .failure(let error):
        future.fail(error)
      }
    }
    return future
  }
  @discardableResult
  public func wait() throws -> T {
    var result: FutureResult<T>!
    let semaphore = DispatchSemaphore(value: 0)
    pipe {
      result = $0
      semaphore.signal()
    }
    semaphore.wait()
    switch result! {
    case .success(let value):
      return value
    case .failure(let error):
      throw error
    }
  }
  
  public func set(_ value: T?, _ error: Error?) {
    if let error = error {
      fail(error)
    } else if let value = value {
      success(value)
    } else {
      fail(FutureError.nilValue)
    }
  }
  public func success(_ value: T) {
    resolve(.success(value))
  }
  public func fail(_ error: Error) {
    resolve(.failure(error))
  }
  public func resolve(_ resolver: () throws -> (T)) {
    do {
      let result = try resolver()
      success(result)
    } catch {
      fail(error)
    }
  }
  public func resolve(_ value: FutureResult<T>) {
    lock.lock()
    guard result == nil else {
      lock.unlock()
      return
    }
    result = value
    let pipes = self.pipes
    lock.unlock()
    
    switch value {
    case .success(let value):
      success(value, 0, pipes)
    case .failure(let error):
      failed(error, 0, pipes)
    }
  }
  private func success(_ value: T, _ index: Int, _ pipes: [_Pipe<T>]) {
    guard index < pipes.count else { return }
    pipes[index].success(value) { error in
      if let error = error {
        self.result = .failure(error)
        self.failed(error, index, pipes)
      } else {
        self.success(value, index + 1, pipes)
      }
    }
  }
  private func failed(_ error: Error, _ index: Int, _ pipes: [_Pipe<T>]) {
    guard index < pipes.count else { return }
    pipes[index].fail(error) { newError in
      if let error = newError {
        self.result = .failure(error)
        self.failed(error, index + 1, pipes)
      } else {
        self.failed(error, index + 1, pipes)
      }
    }
  }
}

private class _Pipe<T> {
  private static func anyCompletion(error: Error?) {}
  func resolve(_ value: FutureResult<T>) {
    switch value {
    case .success(let value):
      success(value, completion: _Pipe.anyCompletion)
    case .failure(let error):
      fail(error, completion: _Pipe.anyCompletion)
    }
  }
  func success(_ value: T, completion: @escaping (Error?) -> ()) {
    completion(nil)
  }
  func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
    completion(nil)
  }
}
private class AnyPipe<T>: _Pipe<T> {
  let callback: (FutureResult<T>) throws -> ()
  init(_ callback: @escaping (FutureResult<T>) throws -> ()) {
    self.callback = callback
  }
  override func success(_ value: T, completion: @escaping (Error?) -> ()) {
    do {
      try callback(.success(value))
      completion(nil)
    } catch {
      completion(error)
    }
  }
  override func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
    do {
      try callback(.failure(error))
      completion(nil)
    } catch {
      completion(error)
    }
  }
  class Async: AnyPipe<T> {
    let queue: DispatchQueue
    init(on queue: DispatchQueue, _ callback: @escaping (FutureResult<T>) throws -> ()) {
      self.queue = queue
      super.init(callback)
    }
    override func success(_ value: T, completion: @escaping (Error?) -> ()) {
      queue.async(if: !(queue == .main && Thread.current.isMainThread)) {
        super.success(value, completion: completion)
      }
    }
    override func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
      queue.async(if: !(queue == .main && Thread.current.isMainThread)) {
        super.fail(error, completion: completion)
      }
    }
  }
  class Queue: AnyPipe<T> {
    let queue: OperationQueue
    init(on queue: OperationQueue, _ callback: @escaping (FutureResult<T>) throws -> ()) {
      self.queue = queue
      super.init(callback)
    }
    override func success(_ value: T, completion: @escaping (Error?) -> ()) {
      queue.addOperation {
        super.success(value, completion: completion)
      }
    }
    override func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
      queue.addOperation {
        super.fail(error, completion: completion)
      }
    }
  }
}
private class ResultPipe<T>: _Pipe<T> {
  let callback: (T) throws -> ()
  init(_ callback: @escaping (T) throws -> ()) {
    self.callback = callback
  }
  override func success(_ value: T, completion: @escaping (Error?) -> ()) {
    do {
      try callback(value)
      completion(nil)
    } catch {
      completion(error)
    }
  }
  class Async: ResultPipe<T> {
    let queue: DispatchQueue
    init(on queue: DispatchQueue, _ callback: @escaping (T) throws -> ()) {
      self.queue = queue
      super.init(callback)
    }
    override func success(_ value: T, completion: @escaping (Error?) -> ()) {
      queue.async(if: !(queue == .main && Thread.current.isMainThread)) {
        super.success(value, completion: completion)
      }
    }
  }
}
private class ErrorPipe<T>: _Pipe<T> {
  let callback: (Error) throws -> ()
  init(_ callback: @escaping (Error) throws -> ()) {
    self.callback = callback
  }
  override func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
    do {
      try callback(error)
      completion(nil)
    } catch {
      completion(error)
    }
  }
  class Async: ErrorPipe<T> {
    let queue: DispatchQueue
    init(on queue: DispatchQueue, _ callback: @escaping (Error) throws -> ()) {
      self.queue = queue
      super.init(callback)
    }
    override func fail(_ error: Error, completion: @escaping (Error?) -> ()) {
      queue.async(if: !(queue == .main && Thread.current.isMainThread)) {
        super.fail(error, completion: completion)
      }
    }
  }
}

public protocol _AnyFuture {
  var any: Future<Any> { get }
}


public extension Array where Element: Future<Any> {
  func wait() throws -> [Any] {
    return try map { try $0.wait() }
  }
  func group() -> Future<[Any]> {
    return when(fulfilled: self)
  }
}

public extension DispatchQueue {
  static var some = DispatchQueue(label: "default.queue")
  func async(if condition: Bool, execute: @escaping ()->()) {
    if condition {
      async(execute: execute)
    } else {
      execute()
    }
  }
  func future<T>(_ execute: @escaping ()throws->(T)) -> Future<T> {
    let future = Future<T>()
    async {
      do {
        try future.success(execute())
      } catch {
        future.fail(error)
      }
    }
    return future
  }
  
  func run<T>(_ future: Future<T>, _ code: @escaping ()throws->(T)) {
    async {
      do {
        try future.success(code())
      } catch {
        future.fail(error)
      }
    }
  }
}
