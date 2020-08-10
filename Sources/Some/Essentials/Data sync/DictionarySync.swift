//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 5/4/20.
//

public enum SyncRepeater {
  case always
  case object(AnyWeak)
  var shouldRepeat: Bool {
    switch self {
    case .always:
      return true
    case .object(let object):
      return object.value != nil
    }
  }
}

public class SyncSubscriber<Key, Value>: P<Value> {
  public let key: Key
  init(key: Key) {
    self.key = key
    super.init()
  }
  public override func send(_ value: Value) {
    super.send(value)
  }
}
public protocol DictionarySync: class {
  associatedtype Key: Hashable
  associatedtype Value
  
  var items: [Key: Value] { get set }
  var loading: Set<Key> { get set }
  var isWaiting: Bool { get set }
  var subscribers: [SyncSubscriber<Key, Value>] { get set }
  var bag: Bag { get }
  
  func shouldUpdate(_ value: Value) -> Bool
  func load(_ keys: Set<Key>) -> SingleResult<FutureResult<[Key: Value]>>
  func waitToFill(completion: @escaping ()->())
}
public extension DictionarySync {
  func failed(error: Error) {
    loading.removeAll()
  }
  func at(_ key: Key) -> O<Value> {
    let subscriber = SyncSubscriber<Key, Value>(key: key)
    let result = O<Value>()
    subscriber.add(result)
    if let item = items[key] {
      subscriber.send(item)
      if shouldUpdate(item) {
        append(subscriber: subscriber)
      }
    } else {
      append(subscriber: subscriber)
    }
    return result
  }
  private func append(subscriber: SyncSubscriber<Key, Value>) {
    subscribers.append(subscriber)
    loadIfNeeded()
  }
  private func loadIfNeeded() {
    guard loading.isEmpty else { return }
    guard !subscribers.isEmpty else { return }
    guard !isWaiting else { return }
    isWaiting = true
    waitToFill(completion: waited)
  }
  private func waited() {
    isWaiting = false
    var keys = Set<Key>()
    subscribers.removeAll {
      if !$0.isEmpty {
        keys.insert($0.key)
        return false
      } else {
        return true
      }
    }
    loading = keys
    load(keys).next { result in
      result.onSuccess(self.loaded)
      result.onFailure(self.failed)
    }.store(in: bag)
  }
  private func loaded(data: [Key: Value]) {
    subscribers.removeAll { subscriber in
      if let value = data[subscriber.key] {
        subscriber.send(value)
        return true
      } else {
        return loading.contains(subscriber.key)
      }
    }
    loading.removeAll()
    loadIfNeeded()
  }
}
