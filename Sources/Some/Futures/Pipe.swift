//
//  File.swift
//
//
//  Created by Dmitry on 05.10.2019.
//
import Foundation


#if canImport(Combine)
import Combine
#else
public protocol Cancellable {
  func cancel()
}
#endif

typealias PResult<T> = Swift.Result<T, Error>
public typealias E = P<Void>
public typealias B = P<Bool>
public typealias P2<A,B> = P<(A,B)>

public protocol _PipeStorage: AnyObject {
  func _insert(pipe: Cancellable)
  func _remove(pipe: Cancellable)
}
public protocol PipeStorage: _PipeStorage {
  var pipes: Set<C> { get set }
}
public extension PipeStorage {
  func _insert(pipe: Cancellable) {
    pipes.insert(C(pipe))
  }
  func _remove(pipe: Cancellable) {
    pipes.remove(C(pipe))
  }
}
public class Bag: PipeStorage {
  public var pipes: Set<C> = []
  public init() {}
}
public class SingleItemBag: _PipeStorage {
  public var item: C?
  public init() {}
  public func _insert(pipe: Cancellable) {
    item = C(pipe)
  }
  public func _remove(pipe: Cancellable) {
    item = nil
  }
  public func clean() {
    item = nil
  }
}
public protocol PipeReceiver {
  associatedtype Input
  func receivedInput(_ value: Input)
}

open class S: Cancellable, Hashable {
  public enum Option: UInt8 {
    case autocomplete
  }
  public static var debugEnabled: Bool = false
  open var shouldDebug: Bool = false
  open var pipeName: String { className(self) }
  open var parents = Set<S>()
  open var childs = WeakArray<S>()
  open var isEmpty = true {
    didSet {
      guard isEmpty != oldValue else { return }
      if isEmpty && options[.autocomplete] {
        completed()
      }
    }
  }
  open var storesValues: Bool { false }
  open var requestsValues: Bool { storesValues }
  open weak var storage: _PipeStorage?
  open var options: Option.Set = []
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
  public func cancel() {
    completed()
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
  open func completed() {
    removeFromParents()
    storage?._remove(pipe: self)
    childs.forEach { $0.receivedCompletion(from: self) }
  }
  
  open func receivedCompletion(from child: S) {
    remove(child: child)
  }
  open func add(child: S) {
    child.shouldDebug |= shouldDebug
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
    removeFromParents()
  }
  func log(_ text: @autoclosure ()->String) {
    if S.debugEnabled && shouldDebug {
      _print("[S]: \(pipeName): \(text())")
    }
  }
  @discardableResult
  public func autocomplete() -> Self {
    options[.autocomplete] = true
    return self
  }
}

@dynamicMemberLookup
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
  public subscript<Subject>(dynamicMember keyPath: KeyPath<Input, Subject>) -> P<Subject> {
    map { $0[keyPath: keyPath] }
  }
}
public typealias SingleResult<T> = Pipes.SingleResult<T>

public extension S {
  static let mainStore = Bag()
  /// Store until completed
  func store() {
    store(in: S.mainStore)
  }
//  fileprivate func store(in set: inout Set<AnyCancellable>) {
//    set.insert(self)
//  }
  func store(in holder: _PipeStorage) {
    holder._insert(pipe: self)
    self.storage = holder
  }
}
public extension P {
  static func combine(_ pipes: [P<Input>]) -> P<[Input]> {
    Pipes.AndX(pipes)
  }
  func add(_ pipe: P) {
    add(child: pipe)
  }
  func add<T: PipeReceiver>(_ receiver: T) -> S where T.Input == Input {
    Pipes.Receiver(receiver).add(to: self)
  }
  func add<T: PipeReceiver>(_ receiver: T) where T.Input == Input, T: PipeStorage {
    Pipes.UnownedReceiver(receiver).add(to: self).store(in: receiver)
  }
  func send<First,Second>(_ first: First, _ second: Second) where Input == (First,Second) {
    send((first, second))
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
  func compactMap<T>() -> P<T> where Input == T? {
    compactMap { $0 }
  }
  func compactMap<Output>(_ using: @escaping (Input) -> Output?) -> P<Output> {
    Pipes.CompactMap(mapper: using).add(to: self).outputPipe
  }
  func forEach(_ action: @escaping (Input) -> ()) -> S {
    Pipes.ForEach(action).add(to: self)
  }
  func sink(receiveValue action: @escaping (Input) -> ()) -> S {
    Pipes.ForEach(action).add(to: self)
  }
  func first() -> P<Input> {
    Pipes.First<Input>().add(to: self)
  }
  func first(where filter: @escaping (Input) -> (Bool)) -> P<Input> {
    Pipes.First(where: filter).add(to: self)
  }
  func last() -> P<Input> {
    Pipes.Last<Input>().add(to: self)
  }
  func last(where filter: @escaping (Input) -> (Bool)) -> P<Input> {
    Pipes.Last(where: filter).add(to: self)
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
    forEach { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Input>,
                            where condition: @escaping (Input, Input) -> Bool) -> S {
    forEach { [weak object] value in
      guard let o = object else { return }
      if condition(o[keyPath: path], value) {
        object?[keyPath: path] = value
      }
    }
  }
  func assign<T: AnyObject>(_ object: T, _ path: WritableKeyPath<T, Input?>) -> S {
    forEach { [weak object] value in
      object?[keyPath: path] = value
    }
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Input>)
    where T: PipeStorage {
      forEach { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: object)
  }
  func assign<T>(_ object: T, _ path: WritableKeyPath<T, Input?>)
    where T: PipeStorage {
      forEach { [weak object] value in
      object?[keyPath: path] = value
    }.store(in: object)
  }
  func assign<T: PipeStorageAssignable>(_ assignable: T) where T.AssignedValue == Input {
    forEach {
      assignable.assign(value: $0)
    }.store(in: assignable.pipeStorage)
  }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->(Input)->()) -> S {
    forEach { [weak object] value in
      if let object = object {
        function(object)(value)
      }
    }
  }
  func call<T>(_ object: T, _ function: @escaping (T)->(Input)->())
    where T: AnyObject & PipeStorageAssignable {
      call(weak: object, function).store(in: object.pipeStorage)
  }
  func call<T>(strong object: T, _ function: @escaping (T)->(Input)->()) -> S {
    forEach {
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
    forEach { [weak object] value in
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
    weak(object).forEach { call($0.0)($0.1) }
  }
  func single() -> P<Input> {
    Pipes.SingleResult<Input>().add(to: self)
  }
  func or(_ pipes: P<Input>...) -> P<Input> {
    let pipe = P<Input>()
    pipes.forEach {
      $0.add(pipe)
    }
    return pipe
  }
  func and<Input1>(_ second: P<Input1>) -> Pipes.And<Input, Input1> {
    .init(self, second)
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
  func filterObject0<A,B>(weak a: A) -> P<B> where Input == (A, B), A: AnyObject {
    weak(a).compactMap { $0.0 === $0.1.0 ? $0.1.1 : nil }
  }
  func filter(where condition: @escaping (Input)->Bool) -> P {
    Pipes.Filter(filter: condition).add(to: self)
  }
  func filterObject(_ value: Input) -> P<Void> where Input: AnyObject {
    filter(where: { $0 === value }).void()
  }
  func optimize(_ time: Double, on queue: DispatchQueue = .main) -> Pipes.Optimize<Input> {
    Pipes.Optimize<Input>(queue: queue, time: time).add(to: self)
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
  func removeDuplicates(initialValue: Input? = nil) -> P<Input> {
    Pipes.Unique<Input>(initialValue).add(to: self)
  }
}
public extension P where Input: AnyObject & Equatable {
  func filterWeak(_ value: Input) -> P<Void> {
    weak(value).filter(where: ==).void()
  }
}
public extension P where Input == Void {
  func asTrue() -> P<Bool> { map { true } }
  func asFalse() -> P<Bool> { map { false } }
  func send() { send(()) }
  func map<Some>(_ transform: @escaping @autoclosure ()->(Some)) -> P<Some> {
    map(transform)
  }
  func call<T: AnyObject>(weak object: T, _ function: @escaping (T)->()->()) -> S {
    forEach { [weak object] _ in
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
  func call<T>(strong object: T, _ function: @escaping (T)->()->()) -> S {
    forEach { _ in
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
    Pipes.ForEach(action).add(to: self)
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
  open class ForEach<Input>: P<Input> {
    var action: (Input) -> ()
    open override var requestsValues: Bool { true }
    open override var storesValues: Bool { false }
    init(_ action: @escaping (Input) -> ()) {
      self.action = action
    }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      action(value)
    }
  }
  open class First<Input>: P<Input> {
    var filter: (Input) -> (Bool)
    open override var requestsValues: Bool { true }
    open override var storesValues: Bool { true }
    @Locked var value: Input?
    init(where filter: @escaping (Input) -> (Bool) = { _ in true }) {
      self.filter = filter
    }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      guard self.value == nil else { return }
      guard filter(value) else { return }
      self.value = value
      super.send(value)
      completed()
    }
    open override func request(from child: S) {
      guard let value = value else { return }
      (child as? P<Input>)?.send(value)
    }
  }
  open class Last<Input>: P<Input> {
    var filter: (Input) -> (Bool)
    var lastValue: Input?
    open override var requestsValues: Bool { true }
    open override var storesValues: Bool { true }
    init(where filter: @escaping (Input) -> (Bool) = { _ in true }) {
      self.filter = filter
    }
    public override func send(_ value: Input) {
      guard filter(value) else { return }
      lastValue = value
    }
    open override func receivedCompletion(from child: S) {
      super.receivedCompletion(from: child)
      if let value = lastValue {
        send(value)
      }
      completed()
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
  open class And<Input0, Input1>: P2<Input0, Input1> {
    var i0: Input0? {
      didSet {
        if let i0 = i0, let i1 = i1 {
          send(i0, i1)
        }
      }
    }
    var i1: Input1? {
      didSet {
        if let i0 = i0, let i1 = i1 {
          send(i0, i1)
        }
      }
    }
    init(_ p0: P<Input0>, _ p1: P<Input1>) {
      super.init()
      add(to: p0.forEach { [unowned self] v in
        self.set0(v)
      })
      add(to: p1.forEach { [unowned self] v in
        self.set1(v)
      })
    }
    func set0(_ value: Input0) {
      self.i0 = value
    }
    func set1(_ value: Input1) {
      self.i1 = value
    }
  }
  open class AndX<T>: P<[T]> {
    var values: [T?]
    var waiting: Int
    init(_ pipes: [P<T>]) {
      values = [T?](repeating: nil, count: pipes.count)
      waiting = pipes.count
      super.init()
      pipes.enumerated().forEach { (i, pipe) in
        add(to: pipe.forEach { [unowned self] v in
          if values[i] == nil && waiting > 0 { // checking for waiting is for safety
            waiting -= 1
          }
          values[i] = v
          if waiting == 0 {
            send(values.compactMap())
          }
        })
      }
    }
    open override func request(from child: S) {
      guard waiting == 0 else { return }
      guard let child = child as? P<[T]> else { return }
      child.send(values.compactMap())
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
    var lastPipe: P<Output>?
    init(mapper: @escaping (Input) -> P<Output>) {
      self.mapper = mapper
      super.init()
    }
    public override func send(_ value: Input) {
      log("send(\(value)) \(childs.count)")
      guard !isEmpty else { return }
      let pipe = mapper(value)
      childs.forEach(as: P<Output>.self) {
        lastPipe?.remove(child: $0)
        pipe.add(child: $0)
      }
      lastPipe = pipe
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
        child.receivedCompletion(from: self)
      }
    }
    open override func request(from child: S) {
      log("request(from: \(child))")
      guard let result = result else { return }
      (child as? P<T>)?.send(result)
    }
  }
  open class Unique<T>: P<T> where T: Equatable {
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
      guard result != value else { return }
      self.result = value
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
  open class Optimize<T>: P<T> {
    public enum State {
      case idle
      case waiting
      case queued(T)
    }
    @Locked public var state: State = .idle
    public let waiter: Waiter
    public let time: Double
    public init(queue: DispatchQueue, time: Double) {
      self.waiter = Waiter(queue: queue)
      self.time = time
      super.init()
    }
    open override func send(_ value: T) {
      switch state {
      case .idle:
        _send(value)
        state = .waiting
        waiter.wait(time) { [unowned self] in
          switch state {
          case .queued(let v):
            state = .idle
            _send(v)
          case .waiting:
            state = .idle
          case .idle: break
          }
        }
      case .waiting, .queued:
        state = .queued(value)
      }
    }
    open func _send(_ value: T) {
      super.send(value)
    }
  }
  open class SwitchPipe<T>: P<T> {
    open var isActive: Bool {
      didSet {
        guard isActive != oldValue else { return }
        if isActive {
          connect()
        } else {
          disconnect()
        }
      }
    }
    public var link: (parent: S, child: S)?
    public init(_ isActive: Bool) {
      self.isActive = isActive
    }
    public override func request(from child: S) {
      super.request(from: child)
      if !isActive {
        disconnect()
      }
    }
    open func connect() {
      guard let link = link else { return }
      link.child.add(to: link.parent)
      self.link = nil
      request()
    }
    open func disconnect() {
      if parents.count == 1, let parent = parents.first {
        var child = parent
        while let parent = child.parents.first {
          if parent.parents.count == 1 && parent.childs.count == 1 {
            child = parent
          } else {
            break
          }
        }
        if let parent = child.parents.first {
          child.remove(from: parent)
          link = (parent: parent, child: child)
        }
      }
    }
  }
}

@propertyWrapper
public struct V<Value>: CustomStringConvertible {
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
  public var description: String { "\(value) "}
}

@propertyWrapper
public struct SV<Value>: CustomStringConvertible {
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
        publisher.send(newValue)
      }
    }
  }
  public var description: String { "\(value) "}
}

@propertyWrapper
public struct VE<Value> where Value: Equatable {
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
      guard value != newValue else { return }
      value = newValue
      if let publisher = publisher {
        DispatchQueue.main.async {
          publisher.send(newValue)
        }
      }
    }
  }
}
extension VE: CustomStringConvertible {
  public var description: String { "\(value) "}
}

// MARK: - Assign
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

public class C: Cancellable, Hashable {
  public var body: Cancellable
  public init(_ body: Cancellable) {
    self.body = body
  }
  public func cancel() {
    body.cancel()
  }
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  public static func == (lhs: C, rhs: C) -> Bool {
    lhs === rhs
  }
}
