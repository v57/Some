//
//  Http.swift
//  SomeNetwork
//
//  Created by Dmitry on 14/03/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

#if !os(Linux)
import Foundation

public enum HttpError: Error {
  case failed(Int,String)
  case responseIsNotInJsonFormat
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

public class JsonHttp {
  public var http: Http
  var _auth: (() -> Future<String>?)?
  var responseDataPath: String?
  public func auth(_ auth: @escaping () -> Future<String>?) -> Self {
    _auth = auth
    return self
  }
  public init(_ address: String) {
    http = Http(address)
  }
  public func get(_ api: String) -> Future<AnyReader> {
    if let auth = _auth?() {
      return auth.then { session -> Future<AnyReader> in
        self.http.get(api, session: session).map(self.map)
      }
    } else {
      return http.get(api).map(map)
    }
  }
  public func post(_ api: String, body: @escaping (JsonDictionary)->()) -> Future<AnyReader> {
    if let auth = _auth?() {
      return auth.then { session -> Future<AnyReader> in
        self.http.post(api, session: session, body: body).map(self.map)
      }
    } else {
      return http.post(api, body: body).map(map)
    }
  }
  private func map(data: AnyReader) throws -> AnyReader {
    if let error = try? data.at("error") {
      let code = try error.at("code").int()
      let message = try error.at("message").string()
      throw HttpError.failed(code,message)
    } else {
      guard let path = responseDataPath else { return data }
      return try data.at(path)
    }
  }
}

public struct Http {
  public static func jsonRpc(_ address: String) -> JsonHttp {
    return JsonHttp(address)
  }
  public var address: String
  public var urlSession: URLSession = .some
  public init(_ address: String) {
    self.address = address
  }
  public func get(_ api: String, session: String? = nil) -> Future<AnyReader> {
    let address = self.address + api
    var urlRequest = URLRequest(url: URL(string: address)!, cachePolicy: .reloadIgnoringCacheData)
    urlRequest.httpMethod = "GET"
    if let session = session {
      urlRequest["Authorization"] = "Bearer " + session
    }
    print("{http} \(address) sending")
    return urlSession.send(request: urlRequest).map { data in
      print("{http} \(address) response: \(data.string)")
      do {
        return try AnyReader(json: data)
      } catch {
        print("{http} \(address) failed: cannot convert response to json")
        throw error
      }
    }
  }
  public func post(_ api: String, session: String? = nil, body: (JsonDictionary)->()) -> Future<AnyReader> {
    let address = self.address + api
    var urlRequest = URLRequest(url: URL(string: address)!, cachePolicy: .reloadIgnoringCacheData)
    urlRequest.httpMethod = "POST"
    urlRequest["Content-Type"] = "application/json"
    urlRequest["Accept"] = "application/json"
    if let session = session {
      urlRequest["Authorization"] = "Bearer " + session
    }
    let dictionary = JsonDictionary()
    body(dictionary)
    let body = dictionary.jsonValue()
    do {
      urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
      print("{http} \(address) sending")
      return urlSession.send(request: urlRequest).map { data in
        print("{http} \(address) response: \(data.string)")
        do {
          return try AnyReader(json: data)
        } catch {
          print("{http} \(address) failed: cannot convert response to json")
          throw HttpError.responseIsNotInJsonFormat
        }
      }
    } catch {
      print("{http} \(address) failed: \(error)")
      return Future(error: error)
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
#endif
