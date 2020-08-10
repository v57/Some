//
//  Request.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

private extension String {
  mutating func join(_ string: String, separator: String = " ") {
    if isEmpty {
      self = string
    } else {
      self += separator + string
    }
  }
}

enum JsonRpcError: Error {
  case syntaxError(code: Int, message: String)
  case responseError(code: Int, message: String)
  case emptyResponse
  var localizedDescription: String {
    switch self {
    case let .syntaxError(code: code, message: message):
      return "Json rpc syntax error: \(message) (\(code))"
    case let .responseError(code: code, message: message):
      return "Request failed: \(message) (\(code))"
    case .emptyResponse:
      return "Request failed: Received empty response."
    }
  }
}

/// Work in progress. Will be released in 3.0
open class Request {
  public var id = Request.nextId()
  public var method: String
  public var promise: Future<AnyReader>
  public var isEmpty = false
  private var isSending = false
  
  public init(method: String) {
    self.method = method
    promise = Future()
  }
  
  open func response(data: AnyReader) throws {
    
  }
  open func failed(error: Error) {
    
  }
  open func request() -> Any {
    return [Any]()
  }
  func remove(_ id: Int) -> RemoveResult? {
    if self.id == id {
      return RemoveResult(request: self, isEmpty: true)
    } else {
      return nil
    }
  }
  
  open func requestBody() -> Any {
    var dictionary = [String: Any]()
    dictionary["jsonrpc"] = "2.0"
    dictionary["method"] = method
    dictionary["id"] = id
    dictionary["params"] = request()
    assert(!isSending)
    isSending = true
    return dictionary
  }
  
  open func request(url: URL) throws -> URLRequest {
    var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    let body = requestBody()
    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    _print("request: \(urlRequest.httpBody!.string)")
    return urlRequest
  }
  
  open func checkJsonRpcSyntax(data: AnyReader) throws {
    _print("checking json rpc syntax")
    try data.at("jsonrpc").string().starts(with: "2.")
    if let error = try? data.at("error") {
      let code = try error.at("code").int()
      let message = try error.at("message").string()
      if data.contains("id") {
        throw JsonRpcError.responseError(code: code, message: message)
      } else {
        throw JsonRpcError.syntaxError(code: code, message: message)
      }
    } else {
      _print("reading id")
      try data.at("id").int()
      _print("read id")
    }
  }
  open func _response(data: AnyReader) throws {
    isSending = false
    try checkJsonRpcSyntax(data: data)
    let result = try data.at("result")
    try response(data: result)
    promise.success(result)
  }
  open func _failed(error: Error) {
    isSending = false
    failed(error: error)
    promise.fail(error)
  }
}
private extension Request {
  static var id = 0
  static func nextId() -> Int {
    id += 1
    return id
  }
}

/// Work in progress. Will be released in 3.0
open class CustomRequest: Request {
  public var parameters: Any
  public init(method: String, parameters: Any) {
    self.parameters = parameters
    super.init(method: method)
  }
  open override func request() -> Any {
    return parameters
  }
}

/// Work in progress. Will be released in 3.0
open class RequestBatch: Request {
  public private(set) var requests = [Request]()
  public init() {
    super.init(method: "")
  }
  override func remove(_ id: Int) -> RemoveResult? {
    for (i,request) in requests.enumerated() {
      if let result = request.remove(id), result.isEmpty {
        requests.remove(at: i)
        return RemoveResult(request: result.request, isEmpty: requests.isEmpty)
      }
    }
    return nil
  }
  open func append(_ request: Request) {
    if let batch = request as? RequestBatch {
      requests.append(contentsOf: batch.requests)
      batch.requests.forEach { method.join($0.method) }
    } else {
      requests.append(request)
      method.join(request.method)
    }
  }
  open override func response(data: AnyReader) throws {
    try data.array {
      let id = try $0.at("id").int()
      guard let request = requests.first(where: {$0.id == id}) else { return }
      do {
        try request._response(data: $0)
      } catch {
        request._failed(error: error)
      }
    }
  }
  open override func _response(data: AnyReader) throws {
    try response(data: data)
    promise.success(data)
  }
  open override func failed(error: Error) {
    for request in requests {
      request._failed(error: error)
    }
  }
  open override func requestBody() -> Any {
    return requests.map { $0.requestBody() }
  }
}

struct RemoveResult {
  var request: Request
  var isEmpty: Bool
}
