//
//  File.swift
//
//
//  Created by Dmitry on 05.10.2019.
//

import Foundation

typealias PResult<T> = Swift.Result<T, Error>
public typealias E = P<Void>
public typealias B = P<Bool>
public typealias P2<A,B> = P<(A,B)>

public protocol PipeStorage: class {
  var pipes: Set<S> { get set }
}
public class Bag: PipeStorage {
  public var pipes: Set<S> = []
  public init() {}
}
public protocol PipeReceiver {
  associatedtype Input
  func receivedInput(_ value: Input)
}

open class S: Hashable {
  open var pipeName: String { className(self) }
  open var parents = Set<S>()
  open var childs = WeakArray<S>()
  open var isEmpty = true
  open var storesValues: Bool { false }
  open var requestsValues: Bool { storesValues }
  var hasRequesters: Bool {
    childs.allObjects.contains(where: { $0.hasRequesters })
  }
  open var debugDescription: String {
    var lines = [String]()
    lines.append(className(self))
    childs.forEach {
      $0.debugDescription.lines.forEach {
        lines.append(".\($0)")
      }
    }
    return lines.joined(separator: "\n")
  }
  
  public init() {
    log("init()")
  }
  open func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  public static func == (lhs: S, rhs: S) -> Bool {
    lhs === rhs
  }
  open func remove(from parent: S) {
    log("remove(from parent: \(parent))")
    guard let index = parents.firstIndex(of: parent) else { return }
    parents.remove(at: index).remove(child: self)
  }
  open func removeFromParents() {
    log("removeFromParents()")
    parents.forEach {
      $0.remove(child: self)
    }
    parents.removeAll()
  }
  open func remove(child: S) {
    log("remove(child: \(child))")
    childs.removeObject(child)
    updateEmptyState()
  }
  open func add(child: S) {
    log("add(child: \(child))")
    childs.append(child)
    child.parents.insert(self)
    child.didMove(to: self)
    updateEmptyState()
    if child.parents.count > 1 {
      request()
    }
  }
  open func close() {
    log("close()")
    removeFromParents()
    if !storesValues {
      childs.forEach {
        if $0.parents.count == 1 {
          $0.close()
        } else {
          remove(child: $0)
        }
      }
    }
  }
  @discardableResult
  open func add(to parent: S) -> Self {
    log("add(to: \(parent))")
    parent.add(child: self)
    return self
  }
  open func request() {
    log("request()")
    parents.forEach {
      $0.request(from: self)
    }
  }
  open func request(from child: S) {
    log("request(from: \(child))")
    parents.forEach {
      $0.request(from: self)
    }
  }
  open func didMove(to parent: S) {
    log("didMove(to: \(parent))")
    if requestsValues {
      request()
    }
  }
  private func updateEmptyState() {
    log("updateEmptyState()")
    let e = childs.isEmpty
    if e != isEmpty {
      isEmpty = e
    }
  }
  deinit {
    log("deinit()")
    _print()
    removeFromParents()
  }
  func log(_ text: String) {
    // Swift.print("\n\(name)\n  \(text)")
  }
}

open class P<Input>: S {
  public override init() {
    super.init()
  }
  open func send(_ value: Input) {
    log("send(\(value)) \(childs.count)")
    childs.forEach(as: P<Input>.self) {
      $0.send(value)
    }
  }
}
public typealias SingleResult<T> = Pipes.SingleResult<T>

public extension S {
  static let mainStore = Bag()
  func alwaysStore() {
    store(in: S.mainStore)
  }
  fileprivate func store(in set: inout Set<S>) {
    set.insert(self)
  }
  func store<Holder: PipeStorage>(in holder: Holder) {
    holder.pipes.insert(self)
  }
}
public extension P {
  func add(_ pipe: P) {
    add(child: pipe)
  }
  func add<T: PipeReceiver>(_ receiver: T) -> S where T.Input == Input {
    Pipes.Receiver(receiver).add(to: self)
  }
  func add<T: PipeReceiver>(_ receiver: T) where T.Input == Input, T: PipeStorage {
    Pipes.UnownedReceiver(receiver).add(to: self).store(in: receiver)
  }
  func osend(_ value: Input?) {
    guard let value = value else { return }
    send(value)
  }
  func map<Output>(_ using: @escaping (Input) -> Output) -> P<Output> {
    Pipes.Map(mapper: using).add(to: self).outputPipe
  }
  func flatMap<Output>(_ type: Output.Type, _ using: @escaping (Input) -> P<Output>) -> P<Output> {
    Pipes.FlatMap(mapper: using).add(to: self).outputPipe
  }
  func flatMap<Output>(_ using: @escaping (Input) -> P<Output>) -> P<Output> {
    Pipes.FlatMap(mapper: using).add(to: self).outputPipe
  }
  func compactMap<Output>(_ using: @escaping (Input) -> Output?) -> P<Output> {
    Pipes.CompactMap(mapper: using).add(to: self).outputPipe
  }
  func next(_ action: @escaping (Input) -> ()) -> S {
    Pipes.Completion(action).add(to: self)
  }
  func replace<T: AnyObject>(unowned object: T) -> P<T> {
    map { [unowned object] _ in object }
  }
  func replace<T: AnyObject>(weak object: T) -> P<T> {
    compactMap { [weak object] _ in object }
  }
  func replace<T>(with value: T) -> P<T> {
    map { _ in value }
  }
  func void() -> P<Void> {
    Pipes.PVoid<Input>().add(to: self).outputPipe
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Input>) -> S {
    next { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Input?>) -> S {
    next { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Input>)
    where T: PipeStorage {
    next { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: &object.pipes)
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Input?>)
    where T: PipeStorage {
    next { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: &object.pipes)
  }
  func assign<T: PipeStorageAssignable>(_ assignable: T) where T.AssignedValue == Input {
    next {
      assignable.assign(value: $0)
    }.store(in: &assignable.pipeStorage.pipes)
  }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->(Input)->()) -> S {
    next { [weak object] value in
      if let object = object {
        function(object)(value)
      }
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->(Input)->())
    where T: AnyObject & PipeStorageAssignable {
      call(weak: object, function).store(in: &object.pipeStorage.pipes)
  }
  func call<T>(strong object: T, _ function: @escaping (T)->(Input)->()) -> S {
    next {
      function(object)($0)
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->(Input)->())
    where T: PipeStorage {
      call(weak: object, function).store(in: object)
  }
  func call<T: AnyObject,A,B>(weak object: T, _ function: @escaping (T)->(A,B)->()) -> S
    where Input == (A,B)
  {
    next { [weak object] value in
      if let object = object {
        function(object)(value.0, value.1)
      }
    }
  }
  func call<T,A,B>(_ object: T, _ function: @escaping (T)->(A,B)->())
    where T: PipeStorage, Input == (A,B) {
      call(weak: object, function).store(in: object)
  }
  func weak<T: AnyObject>(_ object: T) -> P<(T, Input)> {
    Pipes.Weak(object).add(to: self).outputPipe
  }
  func weak<T: AnyObject>(_ object: T, call: @escaping (T)->(Input)->()) -> S {
    weak(object).next { call($0.0)($0.1) }
  }
  func single() -> P<Input> {
    Pipes.SingleResult<Input>().add(to: self)
  }
  func input0<A,B>() -> P<A> where Input == (A, B) {
    map { $0.0 }
  }
  func input1<A,B>() -> P<B> where Input == (A, B) {
    map { $0.1 }
  }
  func filter0<A,B>(weak a: A) -> P<B> where Input == (A, B), A: AnyObject & Equatable {
    weak(a).compactMap { $0.0 == $0.1.0 ? $0.1.1 : nil }
  }
  func filter0<A,B>(_ a: A) -> P<B> where Input == (A, B), A: Equatable {
    compactMap { $0.0 == a ? $0.1 : nil }
  }
  func filter(where condition: @escaping (Input)->Bool) -> P {
    Pipes.Filter(filter: condition).add(to: self)
  }
  func unwrap<T>() -> P<T> where Input == T? {
    compactMap { $0 }
  }
  static func just<Input>(_ value: Input) -> P<Input> {
    Pipes.Just(value)
  }
}
public extension P where Input == Bool {
  func inverted() -> P<Bool> {
    map { !$0 }
  }
}
public extension P where Input: Equatable {
  func filter(_ value: Input) -> P<Void> {
    filter(where: { $0 == value }).void()
  }
}
public extension P where Input: AnyObject & Equatable {
  func filterWeak(_ value: Input) -> P<Void> {
    weak(value).filter(where: ==).void()
  }
}
public extension P where Input == Void {
  func asTrue() -> P<Bool> { map { true } }
  func asFalse() -> P<Bool> { map { true } }
  func send() { send(()) }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->()->()) -> S {
    next { [weak object] _ in
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
      call(weak: object, function).store(in: &object.pipeStorage.pipes)
  }
  func call<T>(strong object: T, _ function: @escaping (T)->()->()) -> S {
    next { _ in
      function(object)()
    }
  }
  func `switch`(true truePipe: P) -> P<Bool> {
    let pipe = P<Bool>()
    self.replace(with: false).add(pipe)
    truePipe.replace(with: true).add(pipe)
    return pipe
  }
  func toggle<O: AnyObject>(_ o: O, _ path: ReferenceWritableKeyPath<O, Bool>) -> S {
    vnext { [weak o] in
      o?[keyPath: path].toggle()
    }
  }
  func vnext(_ action: @escaping () -> ()) -> S {
    Pipes.Completion(action).add(to: self)
  }
  func vmap<Output>(_ using: @escaping () -> Output) -> P<Output> {
    Pipes.Map(mapper: using).add(to: self).outputPipe
  }
  func vflatMap<Output>(_ using: @escaping () -> P<Output>) -> P<Output> {
    Pipes.FlatMap(mapper: using).add(to: self).outputPipe
  }
  func vcompactMap<Output>(_ using: @escaping () -> Output?) -> P<Output> {
    Pipes.CompactMap(mapper: using).add(to: self).outputPipe
  }
}
extension P {
  func makePipe<U>() -> P<U> {
    P<U>().add(to: self)
  }
}
public enum Pipes {
}
extension Pipes {
  open class OutputPipe<Input, Output>: P<Input> {
    var outputPipe: P<Output> { makePipe() }
    public func transform(input: Input) -> Output? { nil }
    open override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      guard !isEmpty else { return }
      guard let output = transform(input: value) else { return }
      childs.forEach(as: P<Output>.self) {
        $0.send(output)
      }
    }
  }
  open class Receiver<T: PipeReceiver>: P<T.Input> {
    let receiver: T
    open override var requestsValues: Bool { true }
    init(_ receiver: T) {
      self.receiver = receiver
    }
    public override func send(_ value: T.Input) {
      log("send(\(value)) \(childs.count)")
      receiver.receivedInput(value)
      super.send(value)
    }
  }
  open class UnownedReceiver<T: AnyObject&PipeReceiver>: P<T.Input> {
    unowned let receiver: T
    open override var requestsValues: Bool { true }
    init(_ receiver: T) {
      self.receiver = receiver
    }
    public override func send(_ value: T.Input) {
      log("send(\(value)) \(childs.count)")
      receiver.receivedInput(value)
      super.send(value)
    }
  }
  open class Switch<Input>: P<Input> {
    var currentValue: Bool = false
    var outputPipe: P<Bool> { makePipe() }
    open override var requestsValues: Bool { true }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      currentValue.toggle()
      childs.forEach(as: P<Bool>.self) {
        $0.send(currentValue)
      }
    }
  }
  open class PVoid<Input>: OutputPipe<Input, Void> {
    public override func transform(input: Input) -> Void? {
      return ()
    }
  }
  open class Completion<Input>: P<Input> {
    var action: (Input) -> ()
    open override var requestsValues: Bool { true }
    init(_ action: @escaping (Input) -> ()) {
      self.action = action
    }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      action(value)
    }
  }
  open class Map<Input, Output>: OutputPipe<Input, Output> {
    var mapper: (Input) -> Output
    init(mapper: @escaping (Input) -> Output) {
      self.mapper = mapper
      super.init()
    }
    public override func transform(input: Input) -> Output? {
      mapper(input)
    }
  }
  open class Filter<Input>: P<Input> {
    var filter: (Input) -> Bool
    init(filter: @escaping (Input) -> Bool) {
      self.filter = filter
      super.init()
    }
    public override func send(_ value: Input) {
      guard filter(value) else { return }
      super.send(value)
    }
  }
  open class FlatMap<Input, Output>: P<Input> {
    var mapper: (Input) -> P<Output>
    var outputPipe: P<Output> { makePipe() }
    init(mapper: @escaping (Input) -> P<Output>) {
      self.mapper = mapper
      super.init()
    }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      guard !isEmpty else { return }
      let pipe = mapper(value)
      childs.forEach(as: P<Output>.self) {
        pipe.add(child: $0)
      }
    }
  }
  open class CompactMap<Input, Output>: OutputPipe<Input, Output> {
    var mapper: (Input) -> Output?
    public override func transform(input: Input) -> Output? {
      mapper(input)
    }
    init(mapper: @escaping (Input) -> Output?) {
      self.mapper = mapper
      super.init()
    }
  }
  open class Weak<T,O>: P<T> where O: AnyObject {
    weak var object: O?
    var outputPipe: P<(O,T)> { makePipe() }
    init(_ object: O?) {
      self.object = object
    }
    public override func send(_ value: T) {
      log("send(\(value)) \(childs.count)")
      if let object = self.object {
        childs.forEach(as: P<(O,T)>.self) {
          $0.send(object, value)
        }
      } else {
        removeFromParents()
      }
    }
  }
  open class Just<T>: P<T> {
    public let result: T
    open override var storesValues: Bool { true }
    
    public init(_ result: T) {
      self.result = result
      super.init()
    }
    public override func send(_ value: T) {
      
    }
    open override func add(child: S) {
      super.add(child: child)
      (child as? P<T>)?.send(result)
    }
    open override func request(from child: S) {
      (child as? P<T>)?.send(result)
    }
  }
  open class SingleResult<T>: P<T> {
    @Locked open var result: T?
    open override var storesValues: Bool { true }
    
    public init(_ result: T?) {
      self.result = result
    }
    public override init() {
      super.init()
    }
    public override func send(_ value: T) {
      log("send(\(value)) \(childs.count)")
      guard result == nil else { return }
      self.result = value
      singleSend(value)
    }
    public func singleSend(_ value: T) {
      super.send(value)
    }
    open override func add(child: S) {
      super.add(child: child)
      if let result = result {
        (child as? P<T>)?.send(result)
      }
    }
    open override func request(from child: S) {
      log("request(from: \(child))")
      guard let result = result else { return }
      (child as? P<T>)?.send(result)
    }
  }
}

@propertyWrapper
public struct V<Value> {
  
  @inlinable // trivially forwarding
  public init(initialValue: Value) {
    self.init(wrappedValue: initialValue)
  }
  public init(wrappedValue: Value) {
    value = wrappedValue
  }
  
  public private(set) var value: Value
  private var publisher: Var<Value>?
  public var projectedValue: Var<Value> {
    mutating get {
      publisher.lazy { Var(value) }
    }
  }
  public var wrappedValue: Value {
    get { value }
    set {
      value = newValue
      if let publisher = publisher {
        DispatchQueue.main.async {
          publisher.send(newValue)
        }
      }
    }
  }
}
extension V: CustomStringConvertible {
  public var description: String { "\(value) "}
}

// MARK:- Assign
public protocol PipeStorageAssignable {
  associatedtype AssignedValue
  var pipeStorage: PipeStorage { get }
  func assign(value: AssignedValue)
}
public struct Assigner<Parent: PipeStorage, T>: PipeStorageAssignable {
  public typealias AssignedValue = T
  public unowned var parent: Parent
  public var pipeStorage: PipeStorage { parent }
  public let assignUsing: (Parent, T)->()
  public init(_ parent: Parent, using: @escaping (Parent, T)->()) {
    self.parent = parent
    assignUsing = using
  }
  public func assign(value: T) {
    assignUsing(parent, value)
  }
}

/*
@dynamicCallable
open class P<T> {
  public var connections = [Connection<T>]()
  public init() {}
  open func send(_ value: T) {
    connections = connections.filter { $0.send(value) }
  }
  open func cancel() {
    connections.forEach { $0.cancel() }
  }
  open func connect(_ connection: Connection<T>) {
    connections.append(connection)
  }
  @discardableResult
  open func dynamicallyCall(withArguments args: [(T)->()]) -> Self {
    guard let action = args.first else { return self }
    next(action)
    return self
  }
//  open func filter(_ filter: PipeFilter) -> P<T> {
//    return filter.start(self)
//  }
}
public extension P {
  static func make(_ use: (P)->()) -> P {
    let pipe = P()
    use(pipe)
    return pipe
  }
  func filter(_ filter: @escaping (T)->(Bool)) -> P<T> {
    return .make { pipe in
      next { if filter($0) { pipe.send($0) }}
    }
  }
  func compactMap<U>(_ transform: @escaping (T)->(U?)) -> P<U> {
    return .make { pipe in
      next { if let v = transform($0) { pipe.send(v) } }
    }
  }
  func map<U>(_ transform: @escaping (T)->(U)) -> P<U> {
    return .make { pipe in
      next { pipe.send(transform($0)) }
    }
  }
  func next(_ action: @escaping (T)->()) {
    connect(HandlerConnection(action))
  }
  func cancelled(_ action: @escaping ()->()) {
    connect(CancelConnection(action))
  }
}
public extension P where T == Void {
  func send() {
    send(())
  }
}
//func make<T>(_ makeRequest: @escaping ()->(Future<T>)) -> P<T> {
//  let pipe = P<T>()
//  var attempt = 0
//  let process: (Error, @escaping ()->()) -> () = { error, retry in
//    attempt += 1
//    wait(max(attempt, 30), retry)
//  }
//  func make<T>(_ pipe: P<T>, _ process: @escaping (Error, @escaping ()->()) -> (), _ makeRequest: @escaping ()->(Future<T>)) {
//    let request = makeRequest()
//    request.success(pipe.send)
//    request.failure {
//      process($0) { make(pipe,process,makeRequest) }
//    }
//  }
//  make(pipe,process,makeRequest)
//  return pipe
//}
//func wait(_ secs: Int, _ action: @escaping ()->()) {
//
//}

open class Connection<T> {
  open func send(_ value: T) -> Bool { true }
  open func cancel() {}
}
class WeakConnection<T,V: AnyObject>: Connection<T> {
  weak var object: V?
  var action: (V, T)->()
  init(_ object: V, _ action: @escaping (V, T)->()) {
    self.object = object
    self.action = action
  }
  override func send(_ value: T) -> Bool {
    guard let object = object else { return false }
    action(object, value)
    return true
  }
}
class PipeConnection<T>: Connection<T> {
  var pipe: P<T>
  init(_ pipe: P<T>) {
    self.pipe = pipe
  }
  override func send(_ value: T) -> Bool {
    pipe.send(value)
    return true
  }
}
class HandlerConnection<T>: Connection<T> {
  var action: (T)->()
  init(_ action: @escaping (T)->()) {
    self.action = action
  }
  override func send(_ value: T) -> Bool {
    action(value)
    return true
  }
}
class CancelConnection<T>: Connection<T> {
  var action: ()->()
  init(_ action: @escaping ()->()) {
    self.action = action
  }
  override func cancel() {
    action()
  }
}
class SuccessConnection<T>: Connection<Result<T>> {
  var action: (T)->()
  init(_ action: @escaping (T)->()) {
    self.action = action
  }
  override func send(_ value: Result<T>) -> Bool {
    guard case .success(let value) = value else { return true }
    action(value)
    return true
  }
}
class FailureConnection<T>: Connection<Result<T>> {
  var action: (Error)->()
  init(_ action: @escaping (Error)->()) {
    self.action = action
  }
  override func send(_ value: Result<T>) -> Bool {
    guard case .failure(let value) = value else { return true }
    action(value)
    return true
  }
}
class PathConnection<O: AnyObject,T>: Connection<T> {
  weak var object: O?
  let path: WritableKeyPath<O, T>
  init(_ object: O, _ path: WritableKeyPath<O, T>) {
    self.object = object
    self.path = path
    super.init()
  }
  override func send(_ value: T) -> Bool {
    guard var object = object else { return false }
    object[keyPath: path] = value
    return true
  }
  static func path(_ object: O, _ path: WritableKeyPath<O, T>) -> PathConnection {
    return PathConnection(object, path)
  }
}
class TogglePathConnection<O: AnyObject, T>: Connection<T> {
  weak var object: O?
  let path: WritableKeyPath<O, Bool>
  init(_ object: O, _ path: WritableKeyPath<O, Bool>) {
    self.object = object
    self.path = path
    super.init()
  }
  override func send(_ value: T) -> Bool {
    guard var object = object else { return false }
    object[keyPath: path].toggle()
    return true
  }
  static func path(_ object: O, _ path: WritableKeyPath<O, Bool>) -> TogglePathConnection {
    return TogglePathConnection(object, path)
  }
}
class OptionalPathConnection<O: AnyObject,T>: Connection<T> {
  weak var object: O?
  let path: WritableKeyPath<O, T?>
  init(_ object: O, _ path: WritableKeyPath<O, T?>) {
    self.object = object
    self.path = path
    super.init()
  }
//  override func send(_ value: T) {
//    object?[keyPath: path] = value
//  }
  static func path(_ object: O, _ path: WritableKeyPath<O, T?>) -> OptionalPathConnection {
    return OptionalPathConnection(object, path)
  }
}
*/
