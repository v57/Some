//
//  url.swift
//  SomeFunctions
//
//  Created by Димасик on 10/13/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension SomeSettings {
  public static var debugFileURL: Bool = true
}

private extension String {
  var fs: Set<String> { Set(components(separatedBy: ".")) }
}

private var documentsURL = FileManager.default.documents // ~/Documents
private var tempURL = FileManager.default.temp
private var cacheURL = FileManager.default.cache
#if os(iOS)
private var homePath = NSHomeDirectory()
#else
private var homePath: String = {
  if #available(OSX 10.12, *) {
    return FileManager.default.homeDirectoryForCurrentUser.path
  } else {
    return NSHomeDirectory()
  }
}()
#endif

private let existsFiles = SafeDictionary<FileURL,Bool>()

extension FileManager {
  var temp: FileURL {
    if #available(iOS 10.0, *), #available(OSX 10.12, *) {
      return FileURL(url: temporaryDirectory)
    } else {
      let path = NSTemporaryDirectory()
      return FileURL(path: path)
    }
  }
  var cache: FileURL {
    
    let url = urls(for: .cachesDirectory, in: .allDomainsMask).first!
    return FileURL(url: url)
  }
  var documents: FileURL {
    let url = urls(for: .documentDirectory, in: .allDomainsMask).first!
    return FileURL(url: url)
  }
}

extension Data {
  public init?(contentsOf url: FileURL) {
    do {
      try self.init(contentsOf: url.url)
    } catch {
      if SomeSettings.debugFileURL {
        print("contentsOf error: \(error)")
      }
      return nil
    }
  }
  public func write(to url: FileURL) throws {
    try write(to: url.url)
  }
}

public enum Directories {
  case documents, cache, temp
  public var path: String {
    return fileURL.path
  }
  public var fileURL: FileURL {
    switch self {
    case .documents: return documentsURL
    case .cache: return cacheURL
    case .temp: return tempURL
    }
  }
}

extension URL {
  public var fileURL: FileURL {
    return FileURL(url: self)
  }
}

extension String {
  public var path: URL { URL(fileURLWithPath: self) }
  public var fileURL: FileURL { FileURL(path: self) }
  public var documentsURL: FileURL {
    return Directories.documents.fileURL + self
  }
  public var cacheURL: FileURL {
    return Directories.cache.fileURL + self
  }
  public var tempURL: FileURL {
    return Directories.temp.fileURL + self
  }
}

func expand(_ path: String) -> String {
  guard !path.isEmpty else { return "" }
  #if !os(iOS)
  if path.first! == "~" {
    return homePath + path.removeFirst(1)
  } else {
    return path
  }
  #else
  return path
  #endif
}

public struct FileURL {
  public var url: URL
  public var path: String {
    return url.path
  }
  #if os(iOS)
  public var nsURL: NSURL {
    return url as NSURL
  }
  #endif
  public init(url: URL) {
    self.url = url
  }
  public init(_ url: URL) {
    self.url = url
  }
  public init(path: String) {
    self.url = URL(fileURLWithPath: expand(path))
  }
  public init(_ path: String) {
    self.url = URL(fileURLWithPath: expand(path))
  }
  
  public static let audioFormats = "aac.adts.ac3.aif.aiff.aifc.caf.mp3.m4a.snd.au.sd2.wav".fs
  public static let imageFormats = "png.tiff.tif.jpeg.jpg.gif.bmp.BMPf.ico.cur.xbm".fs
  public static let videoFormats = "mp4.mov.m4v".fs
  public static var documents: FileURL { documentsURL }
  public static var cache: FileURL { cacheURL }
  public static var temp: FileURL { tempURL }
  public static func set(documents: FileURL) {
    documentsURL = documents
  }
  
  public var isVideo: Bool {
    return FileURL.videoFormats.contains(self.extension)
  }
  public var isImage: Bool {
    return FileURL.imageFormats.contains(self.extension)
  }
  public var isAudio: Bool {
    return FileURL.audioFormats.contains(self.extension)
  }
  public var fileSize: Int64 {
    guard exists else { return 0 }
    do {
      let attr = try FileManager.default.attributesOfItem(atPath: path)
      let fileSize = attr[FileAttributeKey.size] as! UInt64
      return Int64(fileSize)
    } catch {
      if SomeSettings.debugFileURL {
        print("fileSize error: \(error)")
      }
      return 0
    }
  }
  public var isDirectory: Bool { self.extension.isEmpty }
  public var directory: FileURL {
    return FileURL(url: url.deletingLastPathComponent())
  }
  public var content: [FileURL] {
    do {
      return try FileManager.default
        .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        .map(\.fileURL)
    } catch {
      return []
    }
  }
  public var recursiveContent: [FileURL] {
    do {
      return try FileManager.default.subpathsOfDirectory(atPath: path).map { self + $0 }
    } catch {
      return []
    }
  }
  public var contents: [URL] {
    do {
      return try FileManager.default
        .contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    } catch {
      return []
    }
  }
  public func subpaths() -> [String] {
    do {
      let paths = try FileManager.default.subpathsOfDirectory(atPath: path)
      return paths
    } catch {
      return []
    }
  }
  public func printSubpaths() {
    do {
      let paths = try FileManager.default.subpathsOfDirectory(atPath: path)
      for path in paths {
        print(path)
      }
    } catch {
      
    }
  }
  /// returns file name with extension
  public var fileName: String {
    return url.lastPathComponent
  }
  /// returns file name without extension
  public var name: String {
    let fileName = url.lastPathComponent as NSString
    return fileName.deletingPathExtension
  }
  /// returns file extension
  public var `extension`: String {
    return url.pathExtension
  }
  public func open() throws -> Data {
    return try Data(contentsOf: self.url)
  }
  public var data: Data? {
    return Data(contentsOf: self)
  }
  public func delete() {
    do {
      try FileManager.default.removeItem(at: self.url)
      set(exists: false)
    } catch {
      if SomeSettings.debugFileURL {
        print("delete error: \(error)")
      }
    }
  }
  public func copy(to url: FileURL) {
    if url.exists {
      url.delete()
    }
    do {
      try FileManager.default.copyItem(at: self.url, to: url.url)
      url.set(exists: true)
    } catch {
      if SomeSettings.debugFileURL {
        print("copy error: \(error)")
      }
    }
  }
  public func create(subdirectories: Bool = false) {
    guard !systemExists else { return }
    if isDirectory {
      do {
        try FileManager.default
          .createDirectory(at: url, withIntermediateDirectories: subdirectories, attributes: nil)
        set(exists: true)
      } catch {
        if SomeSettings.debugFileURL {
          print("create directory error: \(error)")
        }
      }
    } else {
      directory.create(subdirectories: true)
      let created = FileManager.default
        .createFile(atPath: path, contents: nil, attributes: nil)
      set(exists: created)
      if !created {
        print("fs error: can't create \(self) file")
      }
    }
  }
  public func back() -> FileURL {
    FileURL(url: url.deletingLastPathComponent())
  }
  public func clone(to url: FileURL) {
    guard self != url else { return }
    if url.exists {
      url.delete()
    }
    do {
      try FileManager.default.linkItem(at: self.url, to: url.url)
      url.set(exists: true)
    } catch {
      if SomeSettings.debugFileURL {
        print("move error: \(error)")
      }
    }
  }
  public func move(to url: FileURL) {
    guard self != url else { return }
    if url.exists {
      url.delete()
    }
    do {
      try FileManager.default.moveItem(at: self.url, to: url.url)
      url.set(exists: true)
    } catch {
      if SomeSettings.debugFileURL {
        print("move error: \(error)")
      }
    }
  }
  public var systemExists: Bool {
    return FileManager.default.fileExists(atPath: path)
  }
  public var exists: Bool {
    get {
      if let exists = existsFiles[self] {
        return exists
      } else {
        let exists = FileManager.default.fileExists(atPath: path)
        existsFiles[self] = exists
        return exists
      }
    }
  }
  @inline(__always)
  func set(exists: Bool) {
    existsFiles[self] = exists
  }
  
  
  /// converts /folder/file.jpg to /folder/file.temp.jpg
  public var temp: FileURL {
    let ext = self.extension
    var url = self.url
    url.deletePathExtension()
    url.appendPathExtension("temp")
    url.appendPathExtension(ext)
    return url.fileURL
  }
}

extension FileURL: Hashable {
  public static func ==(lhs: FileURL, rhs: FileURL) -> Bool {
    return lhs.url == rhs.url
  }
  public static func +(lhs: FileURL, rhs: String) -> FileURL {
    return FileURL(url: lhs.url.appendingPathComponent(rhs))
  }
  public static func +=(lhs: inout FileURL, rhs: String) {
    lhs.url.appendPathComponent(rhs)
  }
  public func hash(into hasher: inout Hasher) {
    url.hash(into: &hasher)
  }
}

extension FileURL: CustomStringConvertible {
  public var description: String {
    return path
  }
}

extension Sequence where Iterator.Element == FileURL {
  public var files: [FileURL] {
    return filter { !$0.isDirectory && $0.name != ".DS_Store" }
  }
  public var folders: [FileURL] {
    return filter { $0.isDirectory }
  }
  public var images: [FileURL] {
    return filter { $0.isImage }
  }
  public var videos: [FileURL] {
    return filter { $0.isVideo }
  }
}
