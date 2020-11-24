//
//  PriorityQueue.swift
//  SomeNetwork
//
//  Created by Димасик on 2/2/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

public class StreamPriorityQueue: Queue {
  public override var isEmpty: Bool { return operations.isEmpty && completedOperations.isEmpty }
  public var concurrent = 1
  public override var count: Int {
    return operations.count + running.count
  }
  public override var runningCount: Int {
    return running.count
  }
  var operations = Set<StreamOperation>()
  var running = Set<StreamOperation>()
  public init(name: String, concurrent: Int) {
    self.concurrent = concurrent
    super.init(name: name)
  }
  public override func add(_ operation: StreamOperation) {
    guard isEnabled || operation is DataLoadable else { return }
    thread.async {
      self.operations.insert(operation)
      self.nextOperation()
    }
  }
  func next() -> StreamOperation? {
    guard !operations.isEmpty else { return nil }
    var selected: StreamOperation!
    for operation in operations {
      if let previous = selected {
        if operation._priority > previous._priority {
          selected = operation
        }
      } else {
        selected = operation
      }
    }
    assert(!operations.isEmpty)
    operations.remove(selected)
    running.insert(selected)
    return selected
  }
  
  func nextOperation() {
    guard !isPaused else { return }
    guard isEnabled else { return }
    guard running.count < concurrent else { return }
    while let operation = next() {
      if let operation = operation as? StreamOperations, operation.shouldSkip {
        complete(operation, .success, .next, "skipped")
        continue
      } else {
        operation.completed = self.completed
        operation.run()
        return
      }
    }
  }
  override func completed(operation: StreamOperation, status: CompletionStatus, action: CompletionAction) {
    thread.async {
      Queue.completed?(operation,status,action)
      self.running.remove(operation)
      switch action {
      case .next, .stop:
        if operation is DataRepresentable {
          self.save()
        }
        self.complete(operation, status, action, "")
        self.nextOperation()
      case .restart:
        self.operations.insert(operation)
        self.nextOperation()
      }
    }
  }
  
  public override func disable() {
    thread.async {
      self._disable()
    }
  }
  private func _disable() {
    isEnabled = false
    guard !isPaused else { return }
    operations = self.operations.filter { $0 is DataLoadable }
    disconnect()
  }
  public override func pause() {
    thread.async {
      self._pause()
    }
  }
  private func _pause() {
    guard !isPaused else { return }
    isPaused = true
    guard isEnabled else { return }
    disconnect()
  }
  public override func resume() {
    thread.async {
      self._resume()
    }
  }
  private func _resume() {
    guard isPaused else { return }
    isPaused = false
    guard isEnabled else { return }
    for _ in 0..<concurrent {
      nextOperation()
    }
  }
  private func disconnect() {
    var streams = Set<SomeStream>()
    for operation in self.operations {
      if let stream = operation.stream {
        streams.insert(stream)
      }
    }
    for stream in streams {
      stream.disconnect()
    }
  }
  
  public override func save() {
    guard let url = url else { return }
    let data = DataWriter()
    for operation in operations {
      if let binary = operation as? DataRepresentable {
        binary.save(data: data)
        operation.fullPrint("save()")
      }
    }
    if data.isEmpty {
      url.delete()
    } else {
      data.encrypt(password: 0xe86f1891767acfb6)
      try? data.write(to: url)
    }
  }
  public override func load() {
    guard let url = url else { return }
    guard let loadOperations = Stream.loadOperations else { return }
    guard let data = DataReader(url: url) else { return }
    data.decrypt(password: 0xe86f1891767acfb6)
    do {
      let operations = try loadOperations(data)
      guard !operations.isEmpty else { return }
      thread.async {
        for operation in operations {
          self.operations.insert(operation)
          operation.fullPrint("load()")
        }
        for _ in 0..<self.concurrent {
          self.nextOperation()
        }
      }
    } catch {
      
    }
  }
  
  public override func compactMap<T>(block: (StreamOperation)->(T?)) -> [T] {
    return (operations + running).compactMap(block)
  }
  public override func enumerateOperations(using block: (StreamOperation) -> ()) {
    operations.forEach(block)
  }
  public override func enumerateRunning(using block: (StreamOperation) -> ()) {
    running.forEach(block)
  }
}
#endif
