//
//  StreamOperations.swift
//  Events
//
//  Created by Димасик on 2/2/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

open class StreamOperations: StreamOperation {
  public enum Override {
    case none, strong, weak
  }

  public static var lostConnection: (()->())?
  
  override var _priority: Int { return priority }
  public var priority: Int = 0
  var isRunning: Bool = false
  public var operations = [StreamOperation]()
  var position = 0
  var overrideMode = Override.none
  public let time = Time.now
  private var autorepeats = [()->(Bool)]()
  private var completions = [()->()]()
  private var fails = [(Error)->()]()
  private var skips = [()->(Bool)]()
  
  func merge(into operations: StreamOperations) {
    operations.autorepeats += autorepeats
    operations.completions += completions
    operations.fails += fails
    operations.skips += skips
  }
  
  override var fullName: String { return name }
  public var shouldRepeat: Bool {
    for fn in autorepeats {
      if fn() {
        return true
      }
    }
    return false
  }
  public var shouldSkip: Bool {
    for skip in skips {
      let shouldSkip = skip()
      _print("skip(\(shouldSkip))")
      if shouldSkip {
        return true
      }
    }
    return false
  }
  public override init() {
    super.init()
    name = "operation(\(Int.unique))"
  }
  public init(name: String) {
    super.init()
    self.name = name
  }
  
  public func add(_ operation: StreamOperation) {
    operations.append(operation)
  }
  
  
  open func running(operation: StreamOperation) {
    
  }
  open func failed(operation: StreamOperation, error: Error) {
    mainThread {
      self.fails.forEach { $0(error) }
    }
  }
  open func completed(operation: StreamOperation) {
    
  }
  open func failed(error: Error?) {
    
  }
  open func completed() {
    
  }
  open func disconnected() {
    
  }
  
  override func run() {
    guard !isRunning else { return }
    
    while let operation = operations.safe(position) {
      if let operation = operation as? StreamOperations, operation.shouldSkip {
        position += 1
        continue
      } else {
        isRunning = true
        operation.stream = self.stream
        operation.parent = self
        operation.completed = { [weak self] operation, status, action in
          Stream.thread.async {
            self?.operationCompleted(operation: operation, status: status, action: action)
          }
        }
        running(operation: operation)
        operation._print("run()")
        operation.run()
        return
      }
    }
    completion(status: .success, action: .next)
  }
  func operationCompleted(operation: StreamOperation, status: CompletionStatus, action: CompletionAction) {
    switch status {
    case .success:
      completed(operation: operation)
    //        operation.print("success()")
    case .failed(error: let error):
      failed(operation: operation, error: error)
      operation._print("failed(error: \(ename(error))")
    case .lostConnection:
      operation._print("lostConnection()")
    }
    isRunning = false
    switch action {
    case .next:
      position += 1
      if position < operations.count {
        run()
      } else {
        completion(status: status, action: action)
      }
    case .restart:
      if parent == nil {
        if shouldRepeat {
          self.position = 0
          StreamOperations.lostConnection?()
          Time.retryTime.wait {
            self.run()
          }
        } else {
          completion(status: status, action: .next)
        }
      } else {
        self.position = 0
        completion(status: status, action: action)
      }
    case .stop:
      completion(status: status, action: action)
    }
//    print("stream \(stream.stream.id) retains: \(CFGetRetainCount(stream))")
    operation.stream = nil
    operation.parent = nil
  }
  
  
  override func completion(status: CompletionStatus, action: CompletionAction) {
    switch status {
    case .success:
      completed()
    case .failed(error: let error):
      failed(error: error)
    case .lostConnection:
      disconnected()
    }
    switch action {
    case .next:
    //        print("next()")
      break
    case .restart:
      _print("restart()")
    case .stop:
      _print("stop()")
    }
    super.completion(status: status, action: action)
  }
  
  
  @discardableResult
  public func skipOn(condition: @escaping ()->(Bool)) -> Self {
    skips.append(condition)
    return self
  }
  @discardableResult
  public func set(stream: SomeStream) -> Self {
    self.stream = stream
    return self
  }
  @discardableResult
  public func onComplete(action: @escaping ()->()) -> Self {
    completions.append(action)
    return self
  }
  @discardableResult
  public func onFail(action: @escaping (Error)->()) -> Self {
    fails.append(action)
    return self
  }
  @discardableResult
  public func with(name: String) -> Self {
    operations.last?.name = name
    return self
  }
  @discardableResult
  public func rename(_ current: String) -> Self {
    name = current
    return self
  }
  @discardableResult
  public func autorepeat(_ autorepeat: @escaping ()->(Bool)) -> Self {
    autorepeats.append(autorepeat)
    return self
  }
  @discardableResult
  public func autorepeat() -> Self {
    return self.autorepeat { true }
  }
  @discardableResult
  public func override() -> Self {
    overrideMode = .strong
    return self
  }
  @discardableResult
  public func weakOverride() -> Self {
    overrideMode = .weak
    return self
  }
}
#endif
