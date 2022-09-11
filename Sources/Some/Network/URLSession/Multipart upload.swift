//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 13.05.2021.
//

#if !os(Linux) // not sure if it compiles here
import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#elseif os(macOS)
import CoreServices
#endif

public extension FileURL {
  var mimeType: String {
    let tag = kUTTagClassFilenameExtension
    guard let id = UTTypeCreatePreferredIdentifierForTag(tag, self.extension as CFString, nil)?.takeRetainedValue() else { return "application/octet-stream" }
    guard let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
    else { return "application/octet-stream" }
    return contentType as String
  }
}

open class ProgressSingleResult<T>: SingleResult<T> {
  public var progress: Progress
  public init(_ value: T? = nil, _ progress: Progress = Progress()) {
    self.progress = progress
    super.init(value)
  }
}
public extension URLSession {
  static var background: URLSession {
    let id = "some."+Data.random(32).base58(.bitcoin)
    let config = URLSessionConfiguration.background(withIdentifier: id)
    //Determines the maximum number of simulataneous connections to a Host. This is a per session property.
    config.httpMaximumConnectionsPerHost = 1;
    // This controles whether you are allowed to continue your upload/download over cellular access.
    config.allowsCellularAccess = true
    // This makes sure you get an event on your app session launch (in your AppDelegate). (Your app might be killed by system even if your upload/download is going on)
    if #available(macOS 11.0, *) {
      config.sessionSendsLaunchEvents = true
    }
    // This tells the system to wait for connectivity and then resume uploading/downloading. If the network goes away, it will restart from 0.
    config.waitsForConnectivity = true
    // This just makes a new url session using the background configuration.
    return URLSession(configuration: config)
  }
  enum UploadOptions: UInt8 {
    /// Will write uploading body to temp directory
    case alwaysStoreOnDisk
    /// Sends request in background. Sets `alwaysStoreOnDisk` to true
    case background
  }
  func upload(url: URL, file: FileURL, options: UploadOptions.Set = []) -> Future<Data> {
    var options = options
    if options.contains(.background) {
      options.insert(.alwaysStoreOnDisk)
    }
    
    
    let pipe = Future<Data>()
    let data = file.data!
    var request = URLRequest(url: url)
    let id = Data.random(32).base58(.bitcoin)
    let boundary:String = "Boundary-\(id)"
    
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    request.allHTTPHeaderFields = ["Content-Type": "multipart/form-data; boundary=----\(boundary)"]
    
    let fileSize = Int(file.fileSize)
    let prefix = "------\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(file.fileName)\"\r\nContent-Type: \(file.mimeType)\r\n\r\n".data
    let suffix = "\r\n------\(boundary)--".data
    
    let sources: [LocalDataSource] = [.data(prefix), .file(file.url), .data(suffix)]
    let uploadSource: LocalDataSource
    do {
      if !options.contains(.alwaysStoreOnDisk) && fileSize < 5.mb {
        uploadSource = try .data(sources.lazy.map { try $0.data() }.reduce(Data(), +))
      } else {
        let new = "\(id).upload".tempURL
        try new.create(from: sources, progress: nil)
        uploadSource = .file(new.url)
      }
      
      let name = data.sha256[0..<4].hex
      print("[Uploading]: \(name) Uploading \(data.count) bytes to \(url)")
      let task = uploadTask(with: request, from: uploadSource) { data, response, error in
        if let error = error {
          print("[Uploading]: \(name) Upload failed: \(error)")
          pipe.fail(error)
        } else if let data = data, data.count > 0 {
          print("[Uploading]: \(name) Upload successful: \(data.string)")
          pipe.success(data)
        } else {
          print("[Uploading]: \(name) Upload failed: Empty response")
          pipe.fail(JsonRpcError.emptyResponse)
        }
      }
      task.resume()
      pipe.progress = task.progress
      return pipe
    } catch {
      pipe.fail(error)
      return pipe
    }
  }
}
let w = Waiter()

public extension FileURL {
  func create(from sources: [LocalDataSource], progress: Progress?) throws {
    let chunkSize = 1.mb
    create(directory: false)
    let writer = try FileHandle(forWritingTo: url)
    try sources.forEach { source in
      switch source {
      case .file(let partLocation):
        let reader = try FileHandle(forReadingFrom: partLocation)
        var data = reader.readData(ofLength: chunkSize)
        while data.count > 0 {
          writer.write(data)
          progress?.completedUnitCount += Int64(data.count)
          data = reader.readData(ofLength: chunkSize)
        }
        reader.closeFile()
      case .data(let data):
        writer.write(data)
        progress?.completedUnitCount += Int64(data.count)
      }
    }
    writer.closeFile()
  }
}

public enum LocalDataSource {
  case file(URL), data(Data)
  var size: Int64 {
    switch self {
    case .data(let data):
      return Int64(data.count)
    case .file(let url):
      return url.fileURL.fileSize
    }
  }
  func data() throws -> Data {
    switch self {
    case .data(let data):
      return data
    case .file(let url):
      return try url.fileURL.open()
    }
  }
}

extension URLSession {
  func uploadTask(with request: URLRequest, from source: LocalDataSource, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    switch source {
    case .file(let url):
      return uploadTask(with: request, fromFile: url, completionHandler: completionHandler)
    case .data(let data):
//      var request = request
//      request.httpBody = data
      return uploadTask(with: request, from: data, completionHandler: completionHandler)
    }
  }
}
#endif
