//
//  Http.swift
//  SomeNetwork
//
//  Created by Dmitry on 14/03/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

#if !os(Linux)
import Foundation

public enum HttpError: Error, CustomStringConvertible {
  case failed(Int,String)
  case responseIsNotInJsonFormat
  public var description: String {
    switch self {
    case .failed(_, let description):
      return description
    case .responseIsNotInJsonFormat:
      return "Response is not in json format"
    }
  }
}
public class CustomHttp<Response> {
  public typealias RequestMap = (JsonDictionary,(JsonDictionary)->()) -> ()
  public typealias ResponseMap = (AnyReader) throws -> (Response)
  public var http: Http
  var requestMap: RequestMap?
  var responseMap: ResponseMap!
  public init(_ address: String) {
    http = Http(address)
  }
  public func get(_ api: String) -> Future<Response> {
    return http.get(api).map(responseMap)
  }
  public func post(_ api: String, body: (JsonDictionary)->()) -> Future<Response> {
    return http.post(api) { dictionary in
      if let map = requestMap {
        map(dictionary,body)
      } else {
        body(dictionary)
      }
      }.map(responseMap)
  }
}

public class JsonRpcHttp {
  var responseDataPath: String = "data"
  let http: JsonHttp
  public init(_ address: String, _ requestBuilder: @escaping (inout URLRequest)->()) {
    http = JsonHttp(address, requestBuilder)
  }
  
  @discardableResult
  public func get(_ api: String) -> Future<AnyReader> {
    http.get(api).map(map)
  }
  @discardableResult
  public func post(_ api: String, body: @escaping () -> ([String : JsonEncodable])) -> Future<AnyReader> {
    http.post(api, body: body).map(map)
  }
  @discardableResult
  public func post(_ api: String, body: @escaping (JsonDictionary) -> () = { _ in }) -> Future<AnyReader> {
    http.post(api, body: body).map(map)
  }
  @discardableResult
  public func post(_ api: String, filteredBody: [String: Any?]) -> Future<AnyReader> {
    http.post(api, filteredBody: filteredBody).map(map)
  }
  @discardableResult
  public func post(_ api: String, body: Any) -> Future<AnyReader> {
    http.post(api, body: body).map(map)
  }
  @discardableResult
  public func get(_ api: String) async throws -> AnyReader {
    try await map(http.get(api))
  }
  @discardableResult
  public func post(_ api: String, body: @escaping (JsonDictionary)->() = { _ in }) async throws -> AnyReader {
    try await map(http.post(api, body: body))
  }
  @discardableResult
  public func post(_ api: String, body: Any) async throws -> AnyReader {
    try await map(http.post(api, body: body))
  }
  @discardableResult
  public func post(_ api: String, filteredBody: [String: Any?]) async throws -> AnyReader {
    try await map(http.post(api, filteredBody: filteredBody))
  }
  @discardableResult
  public func post(_ api: String, body: @escaping ()->([String: JsonEncodable])) async throws -> AnyReader {
    try await map(http.post(api, body: body))
  }

  private func map(_ data: AnyReader) throws -> AnyReader {
    if let error = try? data.at("error") {
      let code = try error.at("code").int()
      let message = try error.at("message").string()
      throw HttpError.failed(code,message)
    } else {
      return try data.at(responseDataPath)
    }
  }
}

public class JsonHttp {
  public var http: Http
  var _auth: (() async throws -> String?)?
  public func auth(_ auth: @escaping () async throws -> String?) -> Self {
    _auth = auth
    return self
  }
  public init(_ address: String, _ requestBuilder: @escaping (inout URLRequest)->()) {
    http = Http(address, requestBuilder)
  }
  @discardableResult
  public func get(_ api: String) -> Future<AnyReader> {
    Future { try await self.get(api) }
  }
  @discardableResult
  public func post(_ api: String, body: @escaping (JsonDictionary)->() = { _ in }) -> Future<AnyReader> {
    Future { try await self.post(api, body: body) }
  }
  @discardableResult
  public func post(_ api: String, body: Any) -> Future<AnyReader> {
    Future { try await self.post(api, body: body) }
  }
  @discardableResult
  public func post(_ api: String, filteredBody: [String: Any?]) -> Future<AnyReader> {
    post(api, body: filteredBody.compactMapValues { $0 })
  }
  @discardableResult
  public func post(_ api: String, body: @escaping ()->([String: JsonEncodable])) -> Future<AnyReader> {
    Future { try await self.post(api, body: body) }
  }
  @discardableResult
  public func get(_ api: String) async throws -> AnyReader {
    try await http.get(api, session: _auth?())
  }
  @discardableResult
  public func post(_ api: String, body: @escaping (JsonDictionary)->() = { _ in }) async throws -> AnyReader {
    try await http.post(api, session: _auth?(), body: body)
  }
  @discardableResult
  public func post(_ api: String, body: Any) async throws -> AnyReader {
    try await http.post(api, session: _auth?(), body: body)
  }
  @discardableResult
  public func post(_ api: String, filteredBody: [String: Any?]) async throws -> AnyReader {
    try await post(api, body: filteredBody.compactMapValues { $0 })
  }
  @discardableResult
  public func post(_ api: String, body: @escaping ()->([String: JsonEncodable])) async throws -> AnyReader {
    try await http.post(api, session: _auth?(), body: { $0.dictionary = body() })
  }
}

public struct Http {
  public static func jsonRpc(_ address: String, requestBuilder: @escaping (inout URLRequest)->()) -> JsonRpcHttp {
    return JsonRpcHttp(address, requestBuilder)
  }
  public var address: String
  public var urlSession: URLSession = .some
  public let requestBuilder: (inout URLRequest)->()
  public init(_ address: String, _ requestBuilder: @escaping (inout URLRequest)->() = { _ in }) {
    self.requestBuilder = requestBuilder
    self.address = address
    if address.last != "/" && address.last != "?" {
      self.address.append("/")
    }
  }
  func createRequest(_ url: URL) -> URLRequest {
    URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
  }
  struct ApiLog {
    let prefix: String
    init(_ api: String) {
      prefix = "\(api) "
    }
    func print(_ string: String) {
      someLog.http("\(prefix)\(string.replacingOccurrences(of: "\n", with: "\n\(prefix)"))")
    }
  }
  public func get(_ api: String, session: String? = nil, silent: Bool = false) -> Future<AnyReader> {
    Future {
      try await self.get(api, session: session, silent: silent)
    }
  }
  public func post(_ api: String, session: String? = nil, body: (JsonDictionary)->()) -> Future<AnyReader> {
    let dictionary = JsonDictionary()
    body(dictionary)
    let body = dictionary.jsonValue()
    return post(api, session: session, body: body)
  }
  public func post(_ api: String, session: String? = nil, body: Any) -> Future<AnyReader> {
    Future {
      try await self.post(api, session: session, body: body)
    }
  }
  public func get(_ api: String, session: String? = nil, silent: Bool = false) async throws -> AnyReader {
    let log = ApiLog(api)
    let address = self.address + api
    var urlRequest = createRequest(URL(string: address)!)
    urlRequest.httpMethod = "GET"
    if let session = session {
      urlRequest["Authorization"] = "Bearer " + session
    }
    if !silent {
      log.print("sending")
    }
    requestBuilder(&urlRequest)
    let data = try await urlSession.send(request: urlRequest, progress: nil)
    if !silent {
      log.print("response: \(data.string)")
    }
    do {
      return try AnyReader(json: data)
    } catch {
      if !silent {
        log.print("failed: cannot convert response to json")
      }
      throw error
    }
  }
  public func post(_ api: String, session: String? = nil, body: (JsonDictionary)->()) async throws -> AnyReader {
    let dictionary = JsonDictionary()
    body(dictionary)
    let body = dictionary.jsonValue()
    return try await post(api, session: session, body: body)
  }
  public func post(_ api: String, session: String? = nil, body: Any) async throws -> AnyReader {
    let log = ApiLog(api)
    let address = self.address + api
    var urlRequest = createRequest(URL(string: address)!)
    urlRequest.httpMethod = "POST"
    urlRequest["Content-Type"] = "application/json"
    urlRequest["Accept"] = "application/json"
    if let session = session {
      urlRequest["Authorization"] = "Bearer " + session
    }
    do {
      urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
      log.print("sending \(urlRequest.httpBody!.string)")
      requestBuilder(&urlRequest)
      let data = try await urlSession.send(request: urlRequest, progress: nil)
      log.print("response: \(data.string)")
      do {
        return try AnyReader(json: data)
      } catch {
        log.print("failed: cannot convert response to json")
        throw HttpError.responseIsNotInJsonFormat
      }
    } catch {
      log.print("failed: \(error)")
      throw error
    }
  }
}

public extension FutureRepeater {
  @discardableResult
  func request() -> Self {
    processError { error, repeater in
      if let error = error as? HttpError {
        switch error {
        case .failed:
          break
        case .responseIsNotInJsonFormat:
          // probably in http format that sent from network provider
          // because of no account balance or maybe some firewall
          // so we will increase timer to level 3
          repeater.attempt = max(repeater.attempt, 3)
        }
      } else {
        // Probably some parsing error
        // We can guess that its because of weird api
      }
      switch repeater.attempt {
      case 0: repeater.delay = 1
      case 1...3: repeater.delay = 3
      case 4: repeater.delay = 15
      case 5: repeater.delay = 30
      default: repeater.delay = 30
      }
    }
    return self
  }
}

public protocol HttpRequester {
  associatedtype Request
  associatedtype Response
  var isAuthorized: Bool { get set }
  func send(request: HttpRequest<Request>) -> Future<Response>
  func shouldRepeat(on error: Error) -> Int // return maximum repeat count
  func isAuthorizationError(_ error: Error) -> Bool
  func authorization() -> Future<Response>?
  func timeout(for attempt: Int) -> Double
}
protocol JsonRpcHttpRequester: HttpRequester {
  
}
extension JsonRpcHttpRequester {
  /// Returns 1000 repeats on lost connection and 3 on 'not in json format'
  func shouldRepeat(on error: Error) -> Int {
    guard let error = error as? HttpError else { return 1_000 }
    switch error {
    case .responseIsNotInJsonFormat:
      return 3
    case .failed:
      return 0
    }
  }
  func isAuthorizationError(_ error: Error) -> Bool {
    guard let error = error as? HttpError else { return false }
    switch error {
    case let .failed(code, message):
      return code == 401 || message == "authorization required"
    default:
      return false
    }
  }
}
public extension HttpRequester {
  func timeout(for attempt: Int) -> Double {
    Double(min(attempt, 15))
  }
  func send(request: HttpRequest<Request>, shouldRepeat: @escaping ()->Bool) -> Future<Response> {
    let future = Future<Response>()
    send(request: request, attempt: 1, shouldRepeat: shouldRepeat, future: future)
    return future
  }
  func post(path: String, authorized: Bool = true, body: Request, shouldRepeat: @escaping ()->Bool) -> Future<Response> {
    send(request: HttpRequest(path: path, type: .post(body), authorization: false, authorized: true), shouldRepeat: shouldRepeat)
  }
  func get(path: String, authorized: Bool = true, shouldRepeat: @escaping ()->Bool) -> Future<Response> {
    send(request: HttpRequest(path: path, type: .get, authorization: false, authorized: true), shouldRepeat: shouldRepeat)
  }
  private func send(request: HttpRequest<Request>, attempt: Int, shouldRepeat: @escaping ()->Bool, future: Future<Response>){
    send(request: request).pipe { result in
      switch result {
      case .success(let response):
        future.success(response)
      case .failure(let error):
        if self.shouldRepeat(on: error) >= attempt && shouldRepeat() {
          send(request: request, attempt: attempt + 1, shouldRepeat: shouldRepeat, future: future)
        } else {
          future.fail(error)
        }
      }
    }
  }
}
public struct HttpRequest<Body> {
  public var path: String
  public var type: RequestType
  public var authorization: Bool
  public var authorized: Bool
  public enum RequestType {
    case get
    case post(Body)
  }
}
#endif
