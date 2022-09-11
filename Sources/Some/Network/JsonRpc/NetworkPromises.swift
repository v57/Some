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
public protocol NetworkStreamProtocol: AnyObject, NetworkProtocol {
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

public typealias ProgressCallback = (Progress) -> ()
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
    let mem100mb = 100.mb
    let disk1gb = 1.gb
    
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
  func setCache(url: URL, data: Data, mimeType: String?) {
    let cache = URLSession.cache
    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
    let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
    let cachedResponse = CachedURLResponse(response: response, data: data, storagePolicy: .allowed)
    cache.storeCachedResponse(cachedResponse, for: request)
  }
  enum SetCacheError: Error {
    case tooLarge // file is larger than 200mb
    case notFound // file not found
  }
  @discardableResult
  func setCache(url: URL, file: FileURL) -> Future<Void> {
    Future {
      try await self.setCache(url: url, file: file)
    }
  }
  func setCache(url: URL, file: FileURL) async throws {
    let size = file.fileSize
    guard size < 200.mb else { throw SetCacheError.tooLarge }
    try await OperationQueue().tryRun {
      guard let data = file.data else { throw SetCacheError.notFound }
      self.setCache(url: url, data: data, mimeType: file.mimeType)
    }
  }
  private func send(request: Request, to url: URL) -> Future<Data> {
    return DispatchQueue.some.future {
      try request.request(url: url)
      }.then(on: .some) { request in
        self.send(request: request)
    }
  }
  class TaskProgressDelegate: NSObject, URLSessionTaskDelegate {
    let progress: ProgressCallback?
    init(_ progress: ProgressCallback?) {
      self.progress = progress
    }
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
      progress?(task.progress)
    }
  }
  func upload(url: URL, data: Data, progress: ProgressCallback?) async throws -> Data {
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
    
    let name = data.sha256[0..<4].hex
    print("[Uploading]: \(name) Uploading \(data.count) bytes to \(url)")
    
    do {
      let data = try await send(request: request, progress: progress)
      print("[Uploading]: \(name) Upload successful: \(data.string)")
      return data
    } catch JsonRpcError.emptyResponse {
      print("[Uploading]: \(name) Upload failed: Empty response")
      throw JsonRpcError.emptyResponse
    } catch {
      print("[Uploading]: \(name) Upload failed: \(error)")
      throw error
    }
  }
  func upload(url: URL, data: Data) -> (pipe: SingleResult<Result<Data, Error>>, progress: Progress) {
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
    
    let name = data.sha256[0..<4].hex
    let pipe = SingleResult<Result<Data, Error>>()
    print("[Uploading]: \(name) Uploading \(data.count) bytes to \(url)")
    let task = dataTask(with: request) { data, response, error in
      if let error = error {
        print("[Uploading]: \(name) Upload failed: \(error)")
        pipe.send(.failure(error))
      } else if let data = data, data.count > 0 {
        print("[Uploading]: \(name) Upload successful: \(data.string)")
        pipe.send(.success(data))
      } else {
        print("[Uploading]: \(name) Upload failed: Empty response")
        pipe.send(.failure(JsonRpcError.emptyResponse))
      }
    }
    task.resume()
    return (pipe, task.progress)
  }
  func send(request: URLRequest, progress: ProgressCallback?) async throws -> Data {
    return try await withUnsafeThrowingContinuation { task in
      let t = self.dataTask(with: request) { data, response, error in
        if let error = error {
          task.resume(throwing: error)
        } else if let data = data, data.count > 0 {
          task.resume(returning: data)
        } else {
          task.resume(throwing: JsonRpcError.emptyResponse)
        }
      }
      t.resume()
      progress?(t.progress)
    }
  }
  func send(request: URLRequest) -> Future<Data> {
    let future = Future<Data>()
    let task = dataTask(with: request) { data, response, error in
      mainThread {
        if let error = error {
          future.fail(error)
        } else if let data = data, data.count > 0 {
          future.success(data)
        } else {
          future.fail(JsonRpcError.emptyResponse)
        }
      }
    }
    task.resume()
    if #available(iOS 11.0, *), #available(OSX 10.13, *) {
      future.progress = task.progress
    }
    return future
  }
}

public extension URL {
  func upload(data: Data, progress: Progress?) -> P<Result<Data, Error>> {
    let (pipe, p) = URLSession.some.upload(url: self, data: data)
    if let progress = progress {
      mainThread {
        progress.addChild(p, withPendingUnitCount: 0)
      }
    }
    return pipe
  }
  func upload(data: Data, progress: Progress?) async throws -> Data {
    try await URLSession.some.upload(url: self, data: data) { p in
      guard let progress = progress else { return }
      mainThread {
        progress.addChild(p, withPendingUnitCount: 0)
      }
    }
  }
}

public enum URLRequestCacheError: Error {
  case cacheNotFound
}
#endif
