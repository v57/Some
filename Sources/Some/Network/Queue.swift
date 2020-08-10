//
//  Queue.swift
//  StreamNetwork
//
//  Created by Димасик on 9/26/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

public enum CompletionStatus {
  case success, failed(error: Error), lostConnection
}

public enum CompletionAction {
  case next, stop, restart
}

extension Time {
  public static var retryTime: Time = 5
}

private func print(_ item: String) {
  guard SomeSettings.stream.debugQueue else { return }
  Swift.print(item)
}

public class StreamQueue: Queue {
  public var operations = [StreamOperation]()
  public override var isEmpty: Bool {
    var a = false
    thread.sync {
      a = operations.isEmpty
    }
    return a
  }
  public override var count: Int {
    return operations.count
  }
  public override var runningCount: Int {
    return isRunning ? 1 : 0
  }
  public override init(name: String) {
    super.init(name: name)
  }
  public override func enumerateOperations(using block: (StreamOperation) -> ()) {
    if isRunning {
      operations.from(1).forEach(block)
    } else {
      operations.forEach(block)
    }
    
  }
  public override func enumerateRunning(using block: (StreamOperation) -> ()) {
    if let operation = operations.first {
      block(operation)
    }
  }
  public override func add(_ operation: StreamOperation) {
    guard isEnabled || operation is DataLoadable else { return }
    
    thread.async {
      if let op = operation as? StreamOperations {
        switch op.overrideMode {
        case .weak:
          if let operation = self.find(operations: op.name) {
            op.merge(into: operation)
            return
          }
        case .strong:
          self._remove(operations: op.name)
          if let operation = self.find(operations: op.name) {
            op.merge(into: operation)
            return
          }
        case .none:
          break
        }
      }
      
      self.operations.append(operation)
      print("\(self.name).add(\(operation.name))")
      self.nextOperation()
    }
  }
  public func remove(operations name: String) {
    thread.async {
      self._remove(operations: name)
    }
  }
  private func find(operations name: String) -> StreamOperations? {
    operations.lazy.compactMap { $0 as? StreamOperations}.first(where: { $0.name == name })
  }
  private func _remove(operations name: String) {
    var ids = [Int]()
    for (i,o) in self.operations.enumerated() {
      guard let o = o as? StreamOperations else { continue }
      guard o.name == name else { continue }
      ids.append(i-ids.count)
    }
    for id in ids {
      if self.isRunning && id == 0 { continue }
      self.operations.remove(at: id)
    }
  }
  private func nextOperation() {
    guard isEnabled else { return }
    guard !isRunning else { return }
    guard !isPaused else { return }
    while let operation = operations.first {
      if let operation = operation as? StreamOperations, operation.shouldSkip {
        removeFirst(.success, .next, "skipped")
        continue
      } else {
        isRunning = true
        print("\(name).running()")
        operation.completed = self.completed
        operation._print("run()",name)
        operation.run()
        return
      }
    }
  }
  override func completed(operation: StreamOperation, status: CompletionStatus, action: CompletionAction) {
    thread.async {
      Queue.completed?(operation,status,action)
      self.isRunning = false
      switch action {
      case .next, .stop:
        self.removeFirst(status, action, "")
        if operation is DataRepresentable {
          self.save()
        }
        self.nextOperation()
      case .restart:
        self.nextOperation()
      }
    }
  }
  
  func removeFirst(_ s: CompletionStatus, _ a: CompletionAction, _ c: String) {
    let o = operations.removeFirst()
    complete(o,s,a,c)
    if operations.isEmpty {
      print("main: idle")
    }
  }
  
  public override func disable() {
    thread.async {
      self.isEnabled = false
      guard !self.isPaused else { return }
      self.disconnect()
      self.operations = self.operations.filter { $0 is DataLoadable }
    }
  }
  public override func pause() {
    thread.async {
      guard !self.isPaused else { return }
      self.isPaused = true
      guard self.isEnabled else { return }
      self.disconnect()
      self.isRunning = false
    }
  }
  public override func resume() {
    thread.async {
      guard self.isPaused else { return }
      self.isPaused = false
      guard self.isEnabled else { return }
      self.nextOperation()
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
        operation._print("save()")
      }
    }
    data.encrypt(password: 0xe26f1a8a31b7089e)
    try? data.write(to: url)
  }
  public override func load() {
    guard let url = url else { return }
    guard let data = DataReader(url: url) else { return }
    data.decrypt(password: 0xe26f1a8a31b7089e)
    guard let loadOperations = Stream.loadOperations else { return }
    do {
      let operations = try loadOperations(data)
      guard !operations.isEmpty else { return }
      thread.async {
        for operation in operations {
          self.operations.append(operation)
          operation._print("load()")
        }
        self.nextOperation()
      }
    } catch {
      
    }
  }
  
  public override func compactMap<T>(block: (StreamOperation)->(T?)) -> [T] {
    return operations.compactMap(block)
  }
}

public class Queue {
  public static var completed: ((StreamOperation, CompletionStatus, CompletionAction) -> ())?
  public var isEmpty: Bool { return true }
  public var url: FileURL?
  public var count: Int { return 0 }
  public var runningCount: Int { return 0 }
  public var name: String
  public var thread: DispatchQueue
  public var isRunning = false
  public var isEnabled = true
  public var isPaused = false
  var completedOperations = [Some.CompletedOperation]()
  
  func completed(operation: StreamOperation, status: CompletionStatus, action: CompletionAction) {}
  init(name: String) {
    self.name = name
    self.thread = DispatchQueue(label: "some.network.queue.\(name)")
  }
  
  public func enumerateRunning(using block: (StreamOperation)->()) {
    
  }
  public func enumerateOperations(using block: (StreamOperation)->()) {
    
  }
  public func add(_ operation: StreamOperation) {}
  public func disable() {}
  public func pause() {}
  public func resume() {}
  public func save() {}
  public func load() {}
  public func compactMap<T>(block: (StreamOperation)->(T?)) -> [T] { return [] }
}
public extension Queue {
  var streams: [SomeStream] {
    return compactMap { $0.stream }
  }
  var description: String {
    var strings = [name]
    if count > 0 {
      strings.append("\(isRunning ? 1 : 0)/\(count)")
    }
    if !isEnabled {
      strings.append("disabled")
    }
    if isPaused {
      strings.append("paused")
    }
    if strings.count == 1 {
      return ""
    } else {
      return strings.joined(separator: " ")
    }
  }
}

extension Stream {
  static let thread = DispatchQueue(label: "some.network.stream")
  public static var loadOperations: ((DataReader)throws->[StreamOperation])?
}

extension StreamOperation: Equatable {
  public static func ==(lhs: StreamOperation, rhs: StreamOperation) -> Bool {
    return lhs === rhs
  }
}
extension StreamOperation: Hashable {
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
}
#endif
