//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 5/21/20.
//

#if !os(Linux)
import Foundation

public protocol NetworkRequest {
  associatedtype Request
  associatedtype Response
  var name: String { get }
  var overrideText: String { get }
  var overrideMode: OverrideMode { get }
  
  var shouldSkip: Bool { get }
  var shouldRepeat: Bool { get }
  
  func prepare(queue: NetworkQueue)
  func create() -> Request
  func makeData() -> Data
  
  func response(from data: DataReader) throws -> Response
  func success(response: Response)
  
  func process(error: Error) throws
}

public typealias NetworkConnection = SomeStream2
open class RootNetworkQueue: NetworkQueue {
  public override init(connection: NetworkConnection) {
    super.init(connection: connection)
    removeCompletedOperations = true
  }
}
struct OperationStatus {
  let time = Time.mcs
  let string: String
  var timeString: String {
    (time / 1000000).dateFormat(date: .none, time: .medium)
  }
  init(_ string: String) {
    self.string = string
  }
}
public enum NetworkError: Error {
  case lostConnection
}
open class NetworkQueue: SomeOperationQueue {
  var statuses: [Int: OperationStatus] = [:]
  var statusesString: String {
    statuses.values
      .sorted { $0.time > $1.time }
      .lazy.map { $0.timeString + " " + $0.string }
      .joined(separator: "\n")
  }
  open override var name: String {
    if statuses.isEmpty {
      return super.name
    } else {
      return """
      \(super.name)
      
      ------------
      \(statusesString)
      """
    }
  }
  open var connection: NetworkConnection
  open var containedRequest: Any? { nil }
  public init(connection: NetworkConnection) {
    self.connection = connection
  }
  open func send(_ data: @escaping () throws -> (Data)) {
    add(NetworkOperation.Send(data: data))
  }
  open func read(_ response: @escaping (DataReader) throws -> ()) {
    add(NetworkOperation.Read(response: response))
  }
  open func lostConnection() {
    (queue as? NetworkQueue)?.lostConnection()
  }
  open func status(_ string: String) {
    (queue as? NetworkQueue)?.set(status: "[\(string)] \(name)", for: ObjectIdentifier(self).hashValue)
  }
  open func set(status: String, for id: Int) {
    statuses[id] = OperationStatus(status)
  }
  func waitResetAndRetry() {
    reset()
    DispatchQueue.main.wait(3) {
      self.retry()
      self.status("Repeat in 3 seconds")
    }
  }
  open class RequestOperation<Request: NetworkRequest>: NetworkQueue {
    public var networkQueue: NetworkQueue {
      if let queue = queue as? NetworkQueue {
        return queue
      } else {
        fatalError("Network operations should run from network queue")
      }
    }
    open override var name: String { request.name }
    open override var overrideText: String { request.overrideText }
    open override var overrideMode: OverrideMode { request.overrideMode }
    open var request: Request
    open override var containedRequest: Any? { request }
    
    public init(connection: NetworkConnection, request: Request) {
      self.request = request
      super.init(connection: connection)
      addOperations()
    }
    open override func prepareToRun() {
      request.prepare(queue: networkQueue)
    }
    open func addOperations() {
      send {
        self.request.makeData()
      }
      read { data in
        let response = try self.request.response(from: data)
        self.completed(response)
      }
    }
    open override func run() {
      status("W")
      if self.request.shouldSkip {
        self.status("SK")
        self.done()
      } else {
        self.status("RN")
        super.run()
      }
    }
    open override func lostConnection() {
      failed(error: NetworkError.lostConnection)
    }
    open override func failed(error: Error) {
      do {
        try request.process(error: error)
        status("SK: \(error)")
        next()
      } catch {
        if request.shouldRepeat {
          status("RP")
          waitResetAndRetry()
        } else {
          status("ER: \(error)")
          super.failed(error: error)
        }
      }
    }
    open func completed(_ response: Request.Response) {
      status("OK")
      request.success(response: response)
    }
  }
}

open class NetworkOperation: SomeOperation {
  public var networkQueue: NetworkQueue {
    if let queue = queue as? NetworkQueue {
      return queue
    } else {
      fatalError("Network operations should run from network queue")
    }
  }
  public var connection: NetworkConnection { networkQueue.connection }
  
  class Send: NetworkOperation {
    override var name: String { "Sending" }
    let data: () throws -> (Data)
    init(data: @escaping () throws -> (Data)) {
      self.data = data
    }
    func connected() {
      do {
        let data = try self.data()
        send(data: data)
      } catch {
        failedToReadData(error: error)
      }
    }
    func send(data: Data) {
      connection.sendPackage(data) { result in
        self.sent(result)
      }
    }
    func failedToReadData(error: Error) {
      self.queue.failed(error: error)
    }
    func notConnected() {
      networkQueue.lostConnection()
    }
    func sent(_ result: StreamResponse) {
      switch result {
      case .success:
        self.queue.next()
      case .lostConnection:
        networkQueue.lostConnection()
      }
    }
    override func run() {
      if connection.isConnected {
        connected()
      } else {
        notConnected()
      }
    }
  }

  class Read: NetworkOperation {
    override var name: String { "Reading" }
    let response: (DataReader) throws ->()
    init(response: @escaping (DataReader) throws -> ()) {
      self.response = response
    }
    func connected() {
      connection.readPackage { result in
        self.received(result: result)
      }
    }
    func received(result: SomeReadOperation.Response) {
      switch result {
      case .success(let data):
        received(data: data)
      case .lostConnection:
        lostConnection()
      }
    }
    func received(data: DataReader) {
      do {
        try self.response(data)
        responseSuccess()
      } catch {
        responseFailed(error: error)
      }
    }
    func responseSuccess() {
      self.queue.next()
    }
    func responseFailed(error: Error) {
      self.queue.failed(error: error)
    }
    func lostConnection() {
      networkQueue.lostConnection()
    }
    func notConnected() {
      networkQueue.lostConnection()
    }
    override func run() {
      if connection.isConnected {
        connected()
      } else {
        notConnected()
      }
    }
  }

  class Connect: NetworkOperation {
    override var name: String { "Connecting" }
    func connected() {
      self.queue.removeCurrent()
      self.queue.retry()
    }
    func connect() {
      connection.connect { success in
        if success {
          self.connected()
        } else {
          self.lostConnection()
        }
      }
    }
    func lostConnection() {
      networkQueue.lostConnection()
    }
    override func run() {
      if connection.isConnected {
        connected()
      } else {
        connect()
      }
    }
  }
}


// MARK: Connect Operation
extension NetworkQueue {
  open class ConnectOperation<Request: NetworkRequest>: RequestOperation<Request> {
    open override func addOperations() {
      add(Connect())
      add(Send {
        self.request.makeData()
      })
      add(Read { data in
        let response = try self.request.response(from: data)
        self.completed(response)
      })
    }
  }
  
  private class Connect: NetworkOperation.Connect {
    override func connected() {
      queue.next()
    }
    override func lostConnection() {
      networkQueue.waitResetAndRetry()
    }
  }
  
  private class Send: NetworkOperation.Send {
    override func failedToReadData(error: Error) {
      notConnected()
    }
    override func notConnected() {
      networkQueue.waitResetAndRetry()
    }
    override func sent(_ result: StreamResponse) {
      switch result {
      case .success:
        queue.next()
      case .lostConnection:
        notConnected()
      }
    }
  }

  private class Read: NetworkOperation.Read {
    override func responseSuccess() {
      self.queue.next()
    }
    override func responseFailed(error: Error) {
      notConnected()
    }
    override func lostConnection() {
      notConnected()
    }
    override func notConnected() {
      networkQueue.waitResetAndRetry()
    }
  }
}
#endif
