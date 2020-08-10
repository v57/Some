//
//  NetworkProvider.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

#if !os(Linux)
import Foundation

extension URLSession {
  public static var authorizationHeader = "Authorization"
  /// Default web3 url session.
  /// Uses custom delegate queue to process responses from non-main thread.
  /// You can set it with .shared or your own session if you want some customization
  public static var some: URLSession = {
    let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())
    return session
  }()
}
extension URLRequest {
  subscript(_ header: String) -> String? {
    get { value(forHTTPHeaderField: header) }
    set { setValue(newValue, forHTTPHeaderField: header) }
  }
}

/// Network provider. Manages your requests
public class NetworkProvider {
  /// Provider url
  public let url: URL
  
  /// Main lock for this provider. Makes it thread safe
  public let lock = NSLock()
  
  /// Time that provider waits before sending all requests
  public var interval: Double = 0.1
  
  /// Contains requests in the current queue.
  /// Queue will be grouped and cleaned when its ready to send.
  public private(set) var queue = RequestBatch()
  
  /// Returns true if queue is not empty and provider waits .interval seconds before send all requests
  public private(set) var isWaiting: Bool = false
  
  /// Transport protocol. By now only implemented URLSession. Its possible to use websockets
  public let transport: NetworkProtocol
  
  public var waitingForResponse = [Request]()
  public var notifications = [String: (AnyReader) throws -> ()]()
  
  /// Init with url. (uses URLSession.some as default NetworkProtocol)
  public init(url: URL) {
    transport = URLSession.some
    self.url = url
  }
  
  /// Init with url and network protocol
  public init(url: URL, transport: NetworkProtocol) {
    self.transport = transport
    self.url = url
    if let transport = transport as? NetworkStreamProtocol {
      transport.response = { [weak self] data in
        self?.response(data: data)
      }
    }
  }
  
  public func response(data: AnyReader) {
    let array = data.forceArray()
    for response in array {
      do {
        if let data = try? response.at("notification") {
          let name = try response.at("method").string()
          do {
            if let function = notifications[name] {
              try function(data)
            } else {
              print("jsonrpc warn: received notification \(name) but i don't know how to work with it")
            }
            try self.notifications[name]?(data)
          } catch {
            print("jsonrpc error: cannot parse notification: \(name) body: \(data.raw)")
          }
        } else {
          let id = try response.at("id").int()
          lock.lock()
          var result: RemoveResult?
          var index = -1
          for (i,request) in waitingForResponse.enumerated() {
            if let r = request.remove(id) {
              index = i
              result = r
              break
            }
          }
          if let result = result {
            if result.isEmpty {
              waitingForResponse.remove(at: index)
            }
            let request = result.request
            lock.unlock()
            do {
              try request._response(data: response)
            } catch {
              print("jsonrpc error: failed response: \(data.raw) for request: \(request)")
              request._failed(error: error)
            }
          } else {
            lock.unlock()
            print("jsonrpc error: request with id \(id) not found")
          }
        }
      } catch {
        print("jsonrpc error: cannot parse response: \(response.raw)")
      }
    }
  }
  
  /// Send jsonrpc request.
  /// Automatically waits for promises to complete then adds request to the queue.
  ///
  /// - Parameters:
  ///   - method: Api method
  ///   - parameters: Input parameters
  /// - Returns: Future with response
  open func send(_ method: String, _ parameters: JEncodable...) -> Future<AnyReader> {
    // Mapping types, requesting promises
    let mapped = parameters.map { $0.jsonRpcValue(with: self) }
    
    // Making request with mapped parameters
    // We will replace promises later after they complete
    let request = CustomRequest(method: method, parameters: mapped)
    
    // Checking for promises and waiting
    let futures = mapped.compactMap { $0 as? Future<Any> }
    futures.group().done(on: .some) { _ in
      // Mapping promise results
      let parameters: [Any] = mapped.map { element in
        if let promise = element as? Future<Any> {
          return (promise.value! as! JEncodable).jsonRpcValue(with: self)
        } else {
          return element
        }
      }
      request.parameters = parameters.count == 1 ? parameters.first! : parameters
      // Sending request
      self.send(request: request)
      }.catch(on: .some, request.promise.fail)
    return request.promise
  }
  
  /// Sends multiple requests without waiting for the queue.
  open func send(requests: [Request]) {
    sync {
      requests.forEach { queue.append($0) }
      sendAll()
    }
  }
  
  /// Appends request to the queue. Waits for .interval seconds then sends
  open func append(request: Request) {
    print("Network: appending request \(request.method)")
    sync {
      queue.append(request)
      wait()
    }
  }
  
  /// Send request without waiting for the queue.
  open func send(request: Request) {
    print("Network: appending request \(request.method)")
    sync {
      queue.append(request)
      sendAll()
    }
  }
  
  /// Sends all request from the current queue.
  /// Automatically called from .send(request:) and append(request:).
  /// Should be runned in .sync { sendAll() } for thread safety
  open func sendAll() {
    cancel()
    guard !queue.isEmpty else { return }
    let request = queue
    waitingForResponse.append(request)
    queue = RequestBatch()
    transport.send(request: request, to: url)
  }
  
  /// Locks current thread executes code and unlocks
  public func sync(_ execute: ()->()) {
    lock.lock()
    execute()
    lock.unlock()
  }
  private func wait() {
    guard !isWaiting else { return }
    isWaiting = true
    
    DispatchQueue.some.asyncAfter(deadline: .now() + interval, execute: waited)
  }
  private func waited() {
    lock.lock()
    defer { lock.unlock() }
    guard isWaiting else { return }
    isWaiting = false
    sendAll()
  }
  private func cancel() {
    guard isWaiting else { return }
    isWaiting = false
  }
}

#endif
