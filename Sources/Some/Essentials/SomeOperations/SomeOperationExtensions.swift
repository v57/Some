//
//  SomeOperationExtensions.swift
//
//
//  Created by Dmitry Kozlov on 5/21/20.
//

import Foundation

public extension SomeOperation {
  static var defaultQueue: DispatchQueue = .main
  static func run(_ run: @escaping ()->()) -> SomeOperation {
    runWithResult(defaultResult(for: run))
  }
  static func runWithResult(_ run: @escaping (SomeOperationQueue)->()) -> SomeOperation {
    Run(run: run)
  }
  static func async(on queue: DispatchQueue = defaultQueue, run: @escaping ()->()) -> SomeOperation {
    asyncWithResult(on: queue, run: defaultResult(for: run))
  }
  static func asyncWithResult(on queue: DispatchQueue = defaultQueue, run: @escaping (SomeOperationQueue)->()) -> SomeOperation {
    RunAsync(queue: queue, run: run)
  }
  static func wait(_ time: TimeInterval, on queue: DispatchQueue = defaultQueue, run: @escaping ()->()) -> SomeOperation {
    waitWithResult(time, on: queue, run: defaultResult(for: run))
  }
  static func waitWithResult(_ time: TimeInterval, on queue: DispatchQueue = defaultQueue, run: @escaping (SomeOperationQueue)->()) -> SomeOperation {
    RunWait(time: time, queue: queue, run: run)
  }
  private static func defaultResult(for action: @escaping ()->()) -> (SomeOperationQueue)->() {
    let result: (SomeOperationQueue)->() = { queue in
      action()
      queue.next()
    }
    return result
  }
}

extension SomeOperation {
  class RunAsync: SomeOperation {
    let dispatchQueue: DispatchQueue
    let action: (SomeOperationQueue)->()
    init(queue: DispatchQueue, run: @escaping (SomeOperationQueue)->()) {
      self.dispatchQueue = queue
      self.action = run
    }
    override func run() {
      dispatchQueue.async {
        self.action(self.queue)
      }
    }
  }
  class RunWait: SomeOperation {
    let time: TimeInterval
    let dispatchQueue: DispatchQueue
    let action: (SomeOperationQueue)->()
    var isCancelled = false
    init(time: TimeInterval, queue: DispatchQueue, run: @escaping (SomeOperationQueue)->()) {
      self.time = time
      self.dispatchQueue = queue
      self.action = run
    }
    override func run() {
      isCancelled = false
      dispatchQueue.asyncAfter(wallDeadline: .now() + time) {
        self.waited()
      }
    }
    func waited() {
      guard !isCancelled else { return }
      action(queue)
    }
    override func cancel() {
      isCancelled = true
      queue.reset()
      isCancelled = false
    }
  }
  class Run: SomeOperation {
    let action: (SomeOperationQueue)->()
    init(run: @escaping (SomeOperationQueue)->()) {
      self.action = run
    }
    override func run() {
      action(queue)
    }
  }
}
