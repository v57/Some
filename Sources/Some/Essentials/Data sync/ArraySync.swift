//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 5/4/20.
//

public struct AnyWeak {
  public weak var value: AnyObject?
  public init(_ value: AnyObject?) {
    self.value = value
  }
}

// MARK: - Client
public protocol ArraySyncClient: AnyObject {
  associatedtype Item
  
  var header: ArraySync.Header { get set }
  var items: PartialSet<Indexed<[Item]>> { get set }
  
  // Requests
  func loadNew(request: ArraySync.LoadNewRequest) -> P<ArraySync.LoadNewResponse<Item>>
  func loadPrevious(request: ArraySync.LoadPreviousRequest) -> P<ArraySync.LoadPreviousResponse<Item>>
  func add(items: [Item]) -> P<Error?>
  func update(items: Indexed<[Item]>) -> P<Error?>
  func clear() -> P<Void>
  
  // Notifications
  func added(items: Indexed<[Item]>)
  func updated(items: Indexed<[Item]>, oldValue: Indexed<[Item]>)
  /// Reset called by response
  func reset()
}

// MARK: Notifications
public extension ArraySyncClient {
  func added(notification: ArraySync.ItemsAdded<Item>) {
    update(header: notification.header, reset: false)
    _added(items: notification.data)
  }
  internal func _added(items: Indexed<[Item]>) {
    guard !items.value.isEmpty else { return }
    let result = self.items.insert(items)
    added(items: items)
    result.changed.forEach { update in
      updated(items: update.1, oldValue: update.0)
    }
  }
  func updated(notification: ArraySync.ItemsUpdated<Item>) {
    update(header: notification.header, reset: false)
    _updated(data: notification.data)
  }
  fileprivate func _updated(data: Indexed<[Item]>) {
    guard let last = items.body.last else { return }
    let range = data.range
    let clamped = last.range.clamped(to: range)
    // Ignoring updates, outside of our loaded range
    guard !clamped.isEmpty else { return }
    if clamped.count == range.count {
      let result = items.insert(data)
      result.changed.forEach { update in
        updated(items: update.1, oldValue: update.0)
      }
    } else {
      // Part of the updates are outside loaded range, so we slicing it
      let result = items.insert(data[nonRelative: clamped])
      result.changed.forEach { update in
        updated(items: update.1, oldValue: update.0)
      }
    }
  }
  func cleared(notification: ArraySync.Cleared) {
    guard header.version != notification.version else { return }
    header.version = notification.version
    items.removeAll()
    reset()
  }
}

// MARK: Mutable requests
public extension ArraySyncClient {
  func add(item: Item) -> P<Error?> {
    add(items: [item])
  }
  func update(item: Indexed<Item>) -> P<Error?> {
    update(items: item.singleItemArray())
  }
}

// MARK: Non mutable requests
public extension ArraySyncClient {
  func loadNew() -> P<Indexed<[Item]>> {
    loadNew(request: .init(header: header)).map {
      self.loadNew(response: $0)
      return $0.data
    }
  }
  func loadNew(response: ArraySync.LoadNewResponse<Item>) {
    self.update(header: response.header, reset: response.shouldReset)
    self._added(items: response.data)
    response.updates.forEach {
      self._updated(data: $0.singleItemArray())
    }
  }
  func loadPrevious() -> P<Indexed<[Item]>> {
    loadPrevious(request: .init(version: header.version, unloadedRange: items.lastUnloadedGap())).map {
      self.update(header: $0.header, reset: $0.shouldReset)
      self._added(items: $0.data)
      return $0.data
    }
  }
  @discardableResult
  private func insert(items: Indexed<[Item]>) -> Indexed<[Item]> {
    let result = self.items.insert(items)
    if result.mergedPrefix > 0 {
      let resultArray = Array(result.combined.value[0..<result.mergedPrefix + items.value.count])
      return Indexed(index: result.combined.index, value: resultArray)
    } else {
      return items
    }
  }
  internal func update(header: ArraySync.Header, reset: Bool) {
    let versionChanged = header.version != self.header.version
    self.header = header
    if reset || versionChanged {
      items.removeAll()
      self.reset()
    }
  }
}

// MARK: - Local functions
public extension ArraySyncClient {
  func clearCache() -> P<Void> {
    loadNew(request: .init(header: .init(version: 0, arraySize: 0, updatesSize: 0))).map { response in
      self.__clearCache(response: response)
      return
    }
  }
  private func __clearCache(response: ArraySync.LoadNewResponse<Item>) {
    self.items.removeAll()
    self.reset()
    self.header = response.header
    self.items.insert(response.data)
    self.added(items: response.data)
    
  }
}

// MARK:- Server
public protocol ArraySyncServer: class {
  associatedtype Item
  // Settings
  var blockSize: Int { get }
  var maxUpdates: Int { get }
  
  // Storage
  var storageVersion: Int { get set }
  var items: [Item] { get set }
  var updates: [Int] { get set }
  
  // Events
  func cleared(notification: ArraySync.Cleared)
  func updated(notification: ArraySync.ItemsUpdated<Item>)
  func added(notification: ArraySync.ItemsAdded<Item>)
  
  // Implementations
  func update(item: Item, with item2: Item) -> Item
  func willAdd(items: Indexed<[Item]>)
}
extension ArraySyncServer where Item: MutableId, Item.IdType == Int {
  func willAdd(items: Indexed<[Item]>) {
    for (index, item) in items.value.enumerated() {
      item.id = index + items.index
    }
  }
}

// MARK: - Array sync
public enum ArraySync {
  public enum Command: UInt8 {
    case add
    case edit
    case clear
    case loadNewItems
    case loadPreviousItems
  }
  public enum Notification: UInt8 {
    case added
    case edited
    case cleared
  }
  public struct Header {
    public var version: Int
    public var itemsCount: Int
    public var updatesSize: Int
    public init() {
      self.version = 0
      self.itemsCount = 0
      self.updatesSize = 0
    }
    public init(version: Int, arraySize: Int, updatesSize: Int) {
      self.version = version
      self.itemsCount = arraySize
      self.updatesSize = updatesSize
    }
  }
  
  // Load new data
  public struct LoadNewRequest {
    public let header: Header
    public init(header: Header) {
      self.header = header
    }
  }
  public struct LoadNewResponse<Item> {
    public let header: Header
    
    public let shouldReset: Bool
    public let data: Indexed<[Item]>
    public let updates: [Indexed<Item>]
    public init(header: Header, shouldReset: Bool, data: Indexed<[Item]>, updates: [Indexed<Item>]) {
      self.header = header
      self.shouldReset = shouldReset
      self.data = data
      self.updates = updates
    }
  }
  
  // Load previous data
  public struct LoadPreviousRequest {
    public let version: Int
    public let unloadedRange: Range<Int>
    public init(version: Int, unloadedRange: Range<Int>) {
      self.version = version
      self.unloadedRange = unloadedRange
    }
  }
  public struct LoadPreviousResponse<Item> {
    public let header: Header
    public let shouldReset: Bool
    public let data: Indexed<[Item]>
    public init(header: Header, shouldReset: Bool, data: Indexed<[Item]>) {
      self.header = header
      self.shouldReset = shouldReset
      self.data = data
    }
  }
  
  // Data updated notification
  public struct ItemsUpdated<Item> {
    public let header: Header
    public let data: Indexed<[Item]>
    public init(header: Header, data: Indexed<[Item]>) {
      self.header = header
      self.data = data
    }
  }
  
  // Data added notification
  public struct ItemsAdded<Item> {
    public let header: Header
    public let data: Indexed<[Item]>
    public init(header: Header, data: Indexed<[Item]>) {
      self.header = header
      self.data = data
    }
  }
  
  // Cleared notification
  public struct Cleared {
    public let version: Int
    public init(version: Int) {
      self.version = version
    }
  }
}

// MARK: Mutable requests
public extension ArraySyncServer {
  @discardableResult
  func add(items: [Item]) -> Int {
    let index = self.items.count
    willAdd(items: Indexed(index: index, value: items))
    self.items.append(contentsOf: items)
    added(notification: .init(header: header, data: index.indexed(items)))
    return index
  }
  func update(items: Indexed<[Item]>) {
    var result = items
    for i in 0..<items.value.count {
      let old = self.items[items.index + i]
      let new = items.value[i]
      result.value[i] = update(item: old, with: new)
    }
    willAdd(items: result)
    self.self.items.replaceSubrange(with: result)
    self.updates += items.index ..< items.index + items.count
    updated(notification: ArraySync.ItemsUpdated(header: header, data: result))
  }
}

// MARK: Non mutable requests
public extension ArraySyncServer {
  private func getUpdates(lastIndex: Int) -> [Indexed<Item>] {
    var result = [Indexed<Item>]()
    result.reserveCapacity(updates.count - lastIndex)
    for i in lastIndex..<updates.count {
      let index = updates[i]
      if index < lastIndex {
        result.append(Indexed(index: index, value: self.items[index]))
      }
    }
    return result
  }
  fileprivate var header: ArraySync.Header {
    ArraySync.Header(version: storageVersion, arraySize: self.items.count, updatesSize: updates.count)
  }
  func loadNew(request: ArraySync.LoadNewRequest) -> ArraySync.LoadNewResponse<Item> {
    let lastIndex = request.header.itemsCount
    let lastUpdate = request.header.updatesSize
    let unloadedCount = self.items.count - lastIndex
    let updatesSize = updates.count - lastUpdate
    if storageVersion != request.header.version || unloadedCount < 0 || updatesSize < 0 || (maxUpdates > 0 && updatesSize > maxUpdates) {
      /// Invalid data received or there are more updates that limits allowed
      let array = max(0, self.items.count - blockSize).indexed(self.items.last(blockSize))
      return .init(header: header, shouldReset: true, data: array, updates: [])
    } else if unloadedCount > blockSize {
      /// Loading `blockSize`amount of items
      let array = lastIndex.indexed(self.items[lastIndex..<lastIndex + blockSize])
      let updates = getUpdates(lastIndex: lastUpdate)
      return .init(header: header, shouldReset: false, data: array, updates: updates)
    } else if unloadedCount == 0 {
      /// Nothing to load
      return .init(header: header, shouldReset: false, data: lastIndex.indexed([]), updates: [])
    } else {
      /// Loading all
      let array = lastIndex.indexed(self.items[lastIndex...])
      let updates = getUpdates(lastIndex: lastUpdate)
      return .init(header: header, shouldReset: false, data: array, updates: updates)
    }
  }
  func loadPrevious(request: ArraySync.LoadPreviousRequest) -> ArraySync.LoadPreviousResponse<Item> {
    let lastIndex = request.unloadedRange.upperBound
    let unloadedCount = min(request.unloadedRange.count, blockSize)
    if storageVersion != request.version || request.unloadedRange.lowerBound < 0 || request.unloadedRange.upperBound >= self.items.count {
      /// Invalid data received or there are more updates that limits allowed. Returning last `blockSize` amount of items
      let array = min(0, self.items.count - blockSize).indexed(self.items.suffix(blockSize))
      return .init(header: header, shouldReset: true, data: array)
    } else if unloadedCount == 0 {
      /// Nothing to load
      return .init(header: header, shouldReset: false, data: lastIndex.indexed([]))
    } else {
      /// Loading all
      let array = lastIndex.indexed(self.items[...request.unloadedRange.upperBound])
      return .init(header: header, shouldReset: false, data: array)
    }
  }
  
  func clear() {
    storageVersion += 1
    self.items.removeAll()
    updates.removeAll()
    cleared(notification: ArraySync.Cleared(version: storageVersion))
  }
}

// MARK: - DataRepresentable


extension ArraySync.Header: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(version: data.next(), arraySize: data.next(), updatesSize: data.next())
  }
  public func save(data: DataWriter) {
    data.append(version)
    data.append(itemsCount)
    data.append(updatesSize)
  }
}

// Load new data
extension ArraySync.LoadNewRequest: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(header: data.next())
  }
  public func save(data: DataWriter) {
    data.append(header)
  }
}
extension ArraySync.LoadNewResponse: DataRepresentable where Item: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(header: data.next(), shouldReset: data.next(), data: data.next(), updates: data.next())
  }
  public func save(data: DataWriter) {
    data.append(header)
    data.append(shouldReset)
    data.append(self.data)
    data.append(updates)
  }
}

// Load previous data
extension ArraySync.LoadPreviousRequest: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(version: data.next(), unloadedRange: data.next())
  }
  public func save(data: DataWriter) {
    data.append(version)
    data.append(unloadedRange)
  }
}
extension ArraySync.LoadPreviousResponse: DataRepresentable where Item: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(header: data.next(), shouldReset: data.next(), data: data.next())
  }
  public func save(data: DataWriter) {
    data.append(header)
    data.append(shouldReset)
    data.append(self.data)
  }
}

// Data updated notification
extension ArraySync.ItemsUpdated: DataRepresentable where Item: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(header: data.next(), data: data.next())
  }
  public func save(data: DataWriter) {
    data.append(header)
    data.append(self.data)
  }
}

// Data added notification
extension ArraySync.ItemsAdded: DataRepresentable where Item: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(header: data.next(), data: data.next())
  }
  public func save(data: DataWriter) {
    data.append(header)
    data.append(self.data)
  }
}

// Cleared notification
extension ArraySync.Cleared: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(version: data.next())
  }
  public func save(data: DataWriter) {
    data.append(version)
  }
}
