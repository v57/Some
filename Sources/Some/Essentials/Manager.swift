//
//  manager.swift
//  SomeFunctions
//
//  Created by Димасик on 28/07/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension SomeSettings {
  public enum ceo {
    public static var debug = true
  }
}

public protocol Manager: AnyObject {
  func start()
  func loaded()
  func pause()
  func resume()
  func close()
  func login()
  func logout()
  func reload()
  func memoryWarning()
}

extension Manager {
  public func start() {}
  public func loaded() {}
  public func pause() {}
  public func resume() {}
  public func close() {}
  public func login() {}
  public func logout() {}
  public func reload() {}
  public func memoryWarning() {}
}

public protocol Versionable {
  static var version: Int { get set }
  static var className: String { get }
}
public extension Versionable {
  static var className: String {
    return Some.className(Self.self)
  }
}
public struct Version: ExpressibleByIntegerLiteral, CustomStringConvertible {
  public let current: Int
  public var loaded: Int = 0
  public init(integerLiteral value: Int) {
    current = value
  }
  public mutating func load(data: DataReader) throws {
    loaded = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(current)
  }
  public static func ==(l: Version, r: Version) -> Bool {
    l.loaded == r.current
  }
  public static func <(l: Version, r: Version) -> Bool {
    l.loaded < r.current
  }
  public static func >(l: Version, r: Version) -> Bool {
    l.loaded > r.current
  }
  public static func >=(l: Version, r: Version) -> Bool {
    l.loaded >= r.current
  }
  public static func <=(l: Version, r: Version) -> Bool {
    l.loaded <= r.current
  }
  public var description: String {
    "current: \(current) loaded: \(loaded)"
  }
}
public protocol Saveable: AnyObject {
  var autosave: Bool { get }
  var version: Version { get set }
  func save(data: DataWriter) throws
  func load(data: DataReader) throws
}
public extension Saveable {
  var autosave: Bool { true }
  var version: Version {
    get { 0 }
    set { }
  }
}

public protocol CustomSaveable: AnyObject {
  func save()
  func load() throws
}

public protocol CustomPath: Saveable {
  var fileName: String { get }
  var dataPrefix: Data? { get }
}

public extension CustomPath {
  var dataPrefix: Data? { return nil }
  func save() throws {
    try save(ceo: .default())
  }
  func save(ceo: SomeCeo) throws {
    let data = ceo.writer(for: self)
    data.append(hash: self)
    ceo.presave(manager: self, data: data)
    try self.save(data: data)
    let url = ceo.url(for: fileName)
    try ceo.save(data: data, manager: self, to: url)
  }
}

extension Saveable {
  public func reload(by: Saveable) {}
}

private func print(_ items: Any...) {
  guard SomeSettings.ceo.debug else { return }
  let output = items.map { "\($0)" }.joined(separator: " ")
  _print("ceo:",output)
}

open class SomeCeo {
  public static var `default`: ()->SomeCeo = { SomeCeo() }
  public static let version: Int = 3
  
  public var path = "some.db"
  var url: FileURL {
    return url(for: path)
  }
  
  public private(set) var managers = [Manager]()
  var versions = [String: Int]()
  @V public var isLoaded = false
  @V public var isPaused = false
  @V public var isLoginned = false
  var saveableManagers: Int = 0
  public var version: Int = 0
  public var dataPrefix: Data?
  public var usePrefixAsDefault = false
  
  var hashChecker = SafeHash<UInt64,String>()
  
  open func setup(data: DataWriter) {
    
  }
  open func setup(data: DataReader) {
    
  }
  
  //  public var removeDbOnLogout: Bool { true }
  //  public var secure: Bool { true }
  //  public var password: UInt64 { return 0xc178c12a4f03e978 }
  //  public var autosave: Bool { true }
  //  public var autoload: Bool { true }
  
  public init() {
    
  }
  open func preload(manager: Saveable, data: DataReader) throws {
    try manager.version.load(data: data)
  }
  open func presave(manager: Saveable, data: DataWriter) {
    if let version = versions[className(manager)] {
      data.append(version)
    } else {
      manager.version.save(data: data)
    }
  }
  open func url(for path: String) -> FileURL {
    return path.documentsURL
  }
  
  open func append(_ manager: Manager) {
    // Checking for manager hash corruption. Safety first
    let name = className(manager)
    hashChecker.insert(hash: name.hash64, value: name)
    
    // Adding manager
    managers.append(manager)
    if manager is Saveable && !(manager is CustomPath) {
      saveableManagers += 1
    }
  }
  
  open func encrypt(data: DataWriter) {
    
  }
  open func decrypt(data: DataReader) {
    
  }
  
  open func start() {
    guard managers.count > 0 else { return }
    print("starting \(managers.count) managers")
    
    createNotifications()
    
    
    let saveable = managers.compactMap { $0 as? Saveable }
    saveable.forEach { versions[className($0)] = $0.version.current }
    managers.forEach { $0.start() }
  }
  
  open func loaded() {
    managers.forEach { $0.loaded() }
  }
  
  open func login() {
    guard !isLoginned else { return }
    isLoginned = true
    managers.forEach { $0.login() }
  }
  open func logout() {
    guard isLoginned else { return }
    isLoginned = false
    managers.forEach { $0.logout() }
  }
  open func memoryWarning() {
    managers.forEach { $0.memoryWarning() }
  }
  
  open func pause() {
    
  }
  open func resume() {
    
  }
  open func close() {
    
  }
  open func writer(for manager: CustomPath?) -> DataWriter {
    let data = DataWriter()
    setup(data: data)
    return data
  }
  open func loadFailed(manager: Manager, error: Error) {
    _print("ceo error: cannot load \(className(manager)). \(error)")
  }
  open func saveFailed(manager: Manager, error: Error) {
    _print("ceo error: cannot save \(className(manager)). \(error)")
  }
  
  open func load() {
    if !url.back().exists {
      url.back().create(subdirectories: true)
    }
    var mdata = [UInt64: DataReader]()
    var i: UInt64 = 0
    open(url: url, manager: nil) { data in
      do {
        var count = try data.int()
        if count == -1 { // flag for ceo version 2.0+
          version = try data.int()
          count = try data.int()
        } else {
          version = 1
        }
        
        for _ in 0..<count {
          let data: DataReader = try data.next()
          setup(data: data)
          if version >= 2 {
            let hash: UInt64 = try data.next()
            mdata[hash] = data
          } else {
            let _: Int64 = try data.next()
            mdata[i] = data
          }
          i += 1
        }
      } catch {
        print("ceo error: \(path) corrupted")
      }
      loaded(manager: nil, data: data)
    }
    i = 0
    for manager in managers {
      do {
        if let customPath = manager as? CustomPath {
          let url = self.url(for: customPath.fileName)
          try open(url: url, manager: customPath) { data in
            setup(data: data)
            try data.hash(manager, version: version)
            try preload(manager: customPath, data: data)
            try customPath.load(data: data)
            loaded(manager: manager, data: data)
          }
        } else if let saveable = manager as? Saveable {
          let name = className(manager)
          var hash = name.hash64
          if version == 1 {
            hash = i
          }
          if let data = mdata[hash] {
            try preload(manager: saveable, data: data)
            try saveable.load(data: data)
            loaded(manager: manager, data: data)
          }
          i += 1
        } else if let customSaveable = manager as? CustomSaveable {
          try customSaveable.load()
        }
      } catch {
        loadFailed(manager: manager, error: error)
      }
    }
  }
  
  open func loaded(manager: Manager?, data: DataReader) {
    
  }
  
  open func save() {
    let start = Time.abs
    
    let data = DataWriter()
    data.append(-1) // ceo 2.0 flag
    data.append(SomeCeo.version)
    data.append(saveableManagers)
    for manager in managers {
      //      let type: String
      //      if manager is CustomSaveable {
      //        type = "CustomSaveable"
      //      } else if manager is CustomDBPath {
      //        type = "CustomDBPath"
      //      } else if manager is Saveable {
      //        type = "Saveable"
      //      } else {
      //        type = "Not saveable"
      //      }
      //      print("ceo: saving \(className(manager)) \(type)")
      do {
        if let manager = manager as? CustomSaveable {
          manager.save()
        } else if let manager = manager as? CustomPath {
          try manager.save(ceo: self)
        } else if let manager = manager as? Saveable {
          let managerData = DataWriter()
          try save(saveable: manager, to: managerData)
          data.append(managerData)
        }
      } catch {
        saveFailed(manager: manager, error: error)
      }
    }
    if saveableManagers > 0 {
      try? save(data: data, manager: nil, to: url)
    }
    print("ceo saved for \(Time.abs - start) seconds")
  }
  open func save(saveable: Saveable, to data: DataWriter) throws {
    data.append(hash: saveable)
    presave(manager: saveable, data: data)
    try saveable.save(data: data)
  }
  
  func createNotifications() {
    #if os(iOS)
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(_pause), name: NSNotification.Name("UIApplicationDidEnterBackgroundNotification"), object: nil)
    center.addObserver(self, selector: #selector(_resume), name: NSNotification.Name("UIApplicationDidBecomeActiveNotification"), object: nil)
    center.addObserver(self, selector: #selector(_close), name: NSNotification.Name("UIApplicationWillTerminateNotification"), object: nil)
    #endif
  }
  private func prefix(for manager: CustomPath?) -> Data? {
    if let manager = manager {
      if let data = manager.dataPrefix {
        return data
      } else if usePrefixAsDefault {
        return manager.dataPrefix
      } else {
        return nil
      }
    } else {
      return dataPrefix
    }
  }
  open func open(url: FileURL, manager: CustomPath?, success: (DataReader)throws->()) rethrows {
    guard url.exists else { return }
    guard var _data = url.data else { return }
    if let prefix = prefix(for: manager) {
      _data.removeFirst(prefix.count)
      _data = _data.copy()
    }
    let data = DataReader(data: _data)
    guard data.count > 0 else { return }
    decrypt(data: data)
    try success(data)
  }
  open func save(data: DataWriter, manager: CustomPath?, to url: FileURL) throws {
    if data.isEmpty {
      url.delete()
    } else {
      encrypt(data: data)
      if let prefix = prefix(for: manager) {
        data.data.insert(contentsOf: prefix, at: 0)
      }
      try data.write(to: url)
    }
  }
  
  @objc func _pause() {
    guard !isPaused else { return }
    isPaused = true
    managers.forEach { $0.pause() }
    pause()
  }
  
  @objc func _resume() {
    guard isPaused else { return }
    isPaused = false
    managers.forEach { $0.resume() }
    resume()
  }
  
  @objc func _close() {
    managers.forEach { $0.close() }
    close()
  }
}

private extension DataWriter {
  func append(hash: Any) {
    let name = className(hash)
    let hash = name.hash64
    append(hash)
  }
}

private extension DataReader {
  func hash(_ value: Any, version: Int) throws {
    let name = className(value)
    let hash = UInt64(name.hash64)
    let dataHash: UInt64 = try next()
    if version >= 2 {
      guard hash == dataHash else { throw corrupted }
    }
  }
}
