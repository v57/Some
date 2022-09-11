//
//  SomeOperation.swift
//
//
//  Created by Dmitry Kozlov on 5/21/20.
//

import Swift

public typealias QueueCompletion = (Error?)->()
open class CompletionQueue: SomeOperationQueue {
  public let completion: QueueCompletion
  public init(completion: @escaping QueueCompletion) {
    self.completion = completion
  }
  open override func cancel() {
    completion(nil)
  }
  open override func done() {
    completion(nil)
  }
  open override func failed(error: Error) {
    completion(error)
  }
}

public enum OverrideMode {
  /// No override
  case none
  /// Do not add item if it already exists.
  case weak
  /// Replace existed item.
  case strong
}
open class SomeOperation {
  open var name: String { String(describing: type(of: self)) }
  open weak var queue: SomeOperationQueue!
  open var totalOperations: Int { 1 }
  open var overrideText: String { name }
  open var overrideMode: OverrideMode { .none }
  public init() {}
  
  /// Prepare operation. You can remove this operation from queue or insert other operation before it starts
  open func prepareToRun() {
    
  }
  open func run(completion: @escaping QueueCompletion) -> CompletionQueue {
    let queue = CompletionQueue(completion: completion)
    queue.add(self)
    return queue
  }
  open func run() {
    queue.next()
  }
  open func cancel() {
    queue?.reset()
    queue?.cancel()
  }
  open func suspend() {
    
  }
  open func failed(error: Error) {
    queue?.failed(error: error)
  }
  
  open func overriding(operation: SomeOperation) {
    
  }
}
