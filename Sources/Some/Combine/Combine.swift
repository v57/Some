//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 05.07.2022.
//

#if canImport(Combine)
import Combine

public extension Cancellable {
  func store(in storage: _PipeStorage) {
    storage._insert(pipe: self)
  }
}

public extension Publisher where Self.Failure == Never {
  func forEach(_ receiveValue: @escaping (Output)->()) -> AnyCancellable {
    sink(receiveValue: receiveValue)
  }
  func add<T: PipeReceiver>(_ receiver: T) -> AnyCancellable where T.Input == Output {
    sink(receiveValue: receiver.receivedInput)
  }
  func add<T: PipeReceiver>(_ receiver: T) where T.Input == Output, T: PipeStorage {
    sink { [weak receiver] in
      receiver?.receivedInput($0)
    }.store(in: receiver)
  }
  func compactMap<T>() -> Publishers.CompactMap<Self, T> where Output == T? {
    compactMap { $0 }
  }
  func replace<T: AnyObject>(unowned object: T) -> Publishers.Map<Self, T> {
    map { [unowned object] _ in object }
  }
  func replace<T: AnyObject>(weak object: T) -> Publishers.CompactMap<Self, T> {
    compactMap { [weak object] _ in object }
  }
  func replace<T>(with value: T) -> Publishers.Map<Self, T> {
    map { _ in value }
  }
  func void() -> Publishers.Map<Self, Void> {
    map { _ in }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Output>) -> AnyCancellable {
    forEach { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Output>,
                            where condition: @escaping (Output, Output) -> Bool) -> AnyCancellable {
    forEach { [weak object] value in
      guard let o = object else { return }
      if condition(o[keyPath: path], value) {
        object?[keyPath: path] = value
      }
    }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Output?>) -> AnyCancellable {
    forEach { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Output>)
    where T: PipeStorage {
      forEach { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: object)
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Output?>)
    where T: PipeStorage {
      forEach { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: object)
  }
  func assign<T: PipeStorageAssignable>(_ assignable: T) where T.AssignedValue == Output {
    forEach {
      assignable.assign(value: $0)
    }.store(in: assignable.pipeStorage)
  }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->(Output)->()) -> AnyCancellable {
    forEach { [weak object] value in
      if let object = object {
        function(object)(value)
      }
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->(Output)->())
    where T: AnyObject & PipeStorageAssignable {
      call(weak: object, function).store(in: object.pipeStorage)
  }
  func call<T>(strong object: T, _ function: @escaping (T)->(Output)->()) -> AnyCancellable {
    forEach {
      function(object)($0)
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->(Output)->())
    where T: PipeStorage {
      call(weak: object, function).store(in: object)
  }
  func call<T: AnyObject,A,B>(weak object: T, _ function: @escaping (T)->(A,B)->()) -> AnyCancellable
    where Output == (A,B)
  {
    forEach { [weak object] value in
      if let object = object {
        function(object)(value.0, value.1)
      }
    }
  }
  func call<T,A,B>(_ object: T, _ function: @escaping (T)->(A,B)->())
    where T: PipeStorage, Output == (A,B) {
      call(weak: object, function).store(in: object)
  }
  func weak<T: AnyObject>(_ object: T) -> Publishers.CompactMap<Self, (T, Output)> {
    compactMap { [weak object] in
      guard let object = object else { return nil }
      return (object, $0)
    }
  }
  func weak<T: AnyObject>(_ object: T, call: @escaping (T)->(Output)->()) -> AnyCancellable {
    weak(object).forEach { call($0.0)($0.1) }
  }
  func single() -> Publishers.First<Self> {
    first()
  }
  func or(_ pipes: P<Output>...) -> P<Output> {
    let pipe = P<Output>()
    pipes.forEach {
      $0.add(pipe)
    }
    return pipe
  }
  func and<P: Publisher>(_ other: P) -> Publishers.CombineLatest<Self, P> {
    combineLatest(other)
  }
  func input0<A,B>() -> Publishers.Map<Self, A> where Output == (A, B) {
    map { $0.0 }
  }
  func input1<A,B>() -> Publishers.Map<Self, B> where Output == (A, B) {
    map { $0.1 }
  }
  func filter0<A,B>(weak a: A) -> Publishers.CompactMap<Self, B> where Output == (A, B), A: AnyObject & Equatable {
    compactMap { [weak a] in a == $0.0 ? $0.1 : nil }
  }
  func filter0<A,B>(_ a: A) -> Publishers.CompactMap<Self, B> where Output == (A, B), A: Equatable {
    compactMap { $0.0 == a ? $0.1 : nil }
  }
  func filterObject0<A,B>(weak a: A) -> Publishers.CompactMap<Self, B>
  where Output == (A, B), A: AnyObject {
    compactMap { [weak a] in a === $0.0 ? $0.1 : nil }
  }
  func filterObject(_ value: Output) -> Publishers.CompactMap<Self, Void> where Output: AnyObject {
    compactMap { $0 === value ? Void() : nil }
  }
  func unwrap<T>() -> Publishers.CompactMap<Self, T> where Output == T? {
    compactMap()
  }
  func optimize(_ time: Double, on runLoop: RunLoop = .main) -> Publishers.Throttle<Self, RunLoop> {
    throttle(for: .seconds(time), scheduler: runLoop, latest: true)
  }
  func toArray<T>() -> Publishers.Map<Self, [T]> where Output == T? {
    map {
      guard let value = $0 else { return [] }
      return [value]
    }
  }
}
public extension Publisher where Self.Output: AnyObject {
  func filter(weak object: Output) -> Publishers.CompactMap<Self, Void> {
    compactMap { [weak object] in
      object === $0 ? () : nil
    }
  }
}
public extension Publisher where Self.Output: Equatable {
  func removeDuplicates(initialValue: Output) -> Publishers.Filter<Self> {
    var value = initialValue
    return filter {
      guard value != $0 else { return false }
      value = $0
      return true
    }
  }
}
public extension Publisher where Self.Output == Bool {
  var inverted: Publishers.Map<Self, Bool> { map { !$0 } }
}
public extension Publisher where Self.Output == Void {
  func asTrue() -> Publishers.Map<Self, Bool> { map { true } }
  func asFalse() -> Publishers.Map<Self, Bool> { map { false } }
  func map<Some>(_ transform: @escaping @autoclosure ()->(Some)) -> Publishers.Map<Self, Some> {
    map(transform)
  }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->()->()) -> AnyCancellable {
    sink { _ in } receiveValue: { [weak object] _ in
      if let object = object {
        function(object)()
      }
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->()->())
    where T: PipeStorage {
      call(weak: object, function).store(in: object)
  }
  func call<T>(_ object: T, _ function: @escaping (T)->()->())
    where T: AnyObject & PipeStorageAssignable {
      call(weak: object, function).store(in: object.pipeStorage)
  }
  func call<T>(strong object: T, _ function: @escaping (T)->()->()) -> AnyCancellable {
    sink { _ in } receiveValue: { _ in
      function(object)()
    }
  }
  func toggle<O: AnyObject>(_ o: O, _ path: ReferenceWritableKeyPath<O, Bool>) -> AnyCancellable {
    sink { _ in } receiveValue: { [weak o] in
      o?[keyPath: path].toggle()
    }
  }
}
#endif
