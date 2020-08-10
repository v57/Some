//
//  NetworkFutures.swift
//  web3swift
//
//  Created by Dmitry on 14/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//
#if !os(Linux)
import Foundation

public protocol NetworkProtocol {
  /// Sends request to url. To get
  func send(request: Request, to url: URL)
}
public protocol NetworkStreamProtocol: class, NetworkProtocol {
  var url: URL { get }
  var response: ((AnyReader) -> ())? { get set }
}


/// Work in progress. Will be released in 3.0
class FutureOperation<T>: Operation {
  let resolver: Future<T>
  let execute: ()throws->(T)
  init(resolver: Future<T>, execute: @escaping ()throws->(T)) {
    self.resolver = resolver
    self.execute = execute
  }
  override func main() {
    do {
      let result = try execute()
      resolver.fulfill(result)
    } catch {
      resolver.reject(error)
    }
  }
}

enum URLError: Error {
  case invalidURLFormat(String)
  var localizedDescription: String {
    switch self {
    case .invalidURLFormat(let string):
      return "Invalid url format: \(string)"
    }
  }
}

public struct DownloadResponse<T> {
  public var data: T
  public var cached: Bool
  public init(data: T, cached: Bool) {
    self.data = data
    self.cached = cached
  }
}

extension URLSession: NetworkProtocol {
  public func send(request: Request, to url: URL) {
    send(request: request, to: url).done(on: .some) { data in
      _print("response: \(data.string)")
      let response = try AnyReader(json: data)
      do {
        try request._response(data: response)
      } catch {
        request._failed(error: error)
      }
      }.catch(on: .some, request._failed)
  }
}
public extension URLSession {
  static let cache: URLCache = {
    let mem100mb = 100*1024*1024
    let disk1gb = 1024*1024*1024
    
    if #available(iOS 13.0, *), #available(OSX 10.15, *) {
      URLCache.shared = URLCache(memoryCapacity: mem100mb, diskCapacity: disk1gb, directory: nil)
    } else {
      #if !os(Linux)
      #if !targetEnvironment(macCatalyst)
      URLCache.shared = URLCache(memoryCapacity: mem100mb, diskCapacity: disk1gb, diskPath: nil)
      #endif
      #endif
    }
    return URLCache.shared
  }()
  func get(_ string: String) -> Future<Data> {
    guard let url = URL(string: string) else {
      return Future<Data>(error: URLError.invalidURLFormat(string))
    }
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 15)
    return send(request: request)
  }
  func get(url: URL) -> Future<Data> {
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 15)
    return send(request: request)
  }
  func advancedDownload(url: URL) -> Future<DownloadResponse<Data>> {
    let cache = URLSession.cache
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
    if let response = cache.cachedResponse(for: request) {
      return Future(value: DownloadResponse(data: response.data, cached: true))
    } else {
      return send(request: request).map { DownloadResponse(data: $0, cached: false) }
    }
  }
  static var cleared = [URL: Time]()
  func clearCache(url: URL) {
    let cache = URLSession.cache
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
    cache.removeCachedResponse(for: request)
    URLSession.cleared[url] = .now
  }
  func downloadAsync(url: URL) -> Future<Data> {
    let future = Future<Data>()
    DispatchQueue.some.async {
      let cache = URLSession.cache
      let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
      if let data = cache.cachedResponse(for: request)?.data {
        future.success(data)
      } else {
        self.send(request: request).attach(future)
      }
    }
    return future
  }
  func download(url: URL) -> Future<Data> {
    let cache = URLSession.cache
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
    if let time = URLSession.cleared[url], time + 3 >= .now {
      let future = Future<Data>()
      wait(3) {
        self.send(request: request).attach(future)
      }
      return future
    } else {
      if let data = cache.cachedResponse(for: request)?.data {
        return Future(value: data)
      } else {
        return send(request: request)
      }
    }
  }
  private func send(request: Request, to url: URL) -> Future<Data> {
    return DispatchQueue.some.future {
      try request.request(url: url)
      }.then(on: .some) { request in
        self.send(request: request)
    }
  }
  func upload(url: URL, data: Data) -> (SingleResult<Result<Data, Error>>, Progress) {
    var request = URLRequest(url: url)
    let boundary:String = "Boundary-\(UUID().uuidString)"
    
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    request.allHTTPHeaderFields = ["Content-Type": "multipart/form-data; boundary=----\(boundary)"]
    var body = Data()
    body.append("------\(boundary)\r\n".data)
    //Here you have to change the Content-Type
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"some.file\"\r\n".data)
    body.append("Content-Type: application/YourType\r\n\r\n".data)
    body.append(data)
    body.append("\r\n".data)
    body.append("------\(boundary)--".data)
    
    request.httpBody = body
    
    let pipe = SingleResult<Result<Data, Error>>()
    let task = dataTask(with: request) { data, response, error in
      if let error = error {
        pipe.send(.failure(error))
      } else if let data = data, data.count > 0 {
        pipe.send(.success(data))
      } else {
        pipe.send(.failure(JsonRpcError.emptyResponse))
      }
    }
    task.resume()
    return (pipe, task.progress)
  }
  func send(request: URLRequest) -> Future<Data> {
    let future = Future<Data>()
    let task = dataTask(with: request) { data, response, error in
      if let error = error {
        future.fail(error)
      } else if let data = data, data.count > 0 {
        future.success(data)
      } else {
        future.fail(JsonRpcError.emptyResponse)
      }
    }
    task.resume()
    if #available(iOS 11.0, *), #available(OSX 10.13, *) {
      future.progress = task.progress
    }
    return future
  }
}

public enum URLRequestCacheError: Error {
  case cacheNotFound
}
#endif
