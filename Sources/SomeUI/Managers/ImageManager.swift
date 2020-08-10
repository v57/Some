//
//  ImageManager.swift
//  Some
//
//  Created by Димасик on 4/20/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import UIKit
import SomeFunctions

extension UIImage: Cachable {
  public var cacheSize: Int {
    return Int(size.width) * Int(size.height)
  }
}

public extension FileURL {
  var cachedImage: UIImage? {
    return imageManager.image(ifContains: self)?.original
  }
  func deleteCache() {
    imageManager.delete(self)
  }
  func cache(image: UIImage) {
    let cImage = imageManager.image(for: self)
    cImage.set(original: image)
  }
  func write(image: UIImage, _ format: ImageFormat) {
    let cImage = imageManager.image(for: self)
    cImage.set(original: image)
    run { url in
      let data = format.process(image: image)
      self.write(data: data)
    }
  }
  func write(image: UIImage, _ format: ImageFormat, _ options: ImageOperation) {
    let cImage = imageManager.image(for: self)
    run { url in
      let image = options.process(image: image)
      cImage.set(original: image)
      
      let data = format.process(image: image)
      self.write(data: data)
    }
  }
  func image() -> UIImage? {
    return UIImage(contentsOfFile: path)
  }
  func image(completion: @escaping (UIImage) -> ()) {
    let image = imageManager.image(for: self)
    image.image(completion: completion)
  }
  func image(with operation: ImageOperation?, completion: @escaping (UIImage)->()) {
    let image = imageManager.image(for: self)
    if let operation = operation {
      image.image(with: operation, completion: completion)
    } else {
      image.image(completion: completion)
    }
  }
}

open class ImageOperation {
  public static func resize(size: CGSize) -> ImageOperation {
    return ResizeOperation(size: size)
  }
  public static func roundedCorners(radius: CGFloat, size: CGSize) -> ImageOperation {
    return RoundedCornersOperation(size: size, cornerRadius: radius)
  }
  public static func circle(width: CGFloat) -> ImageOperation {
    return CircleOperation(width: width)
  }
  public static func limit(size: CGFloat) -> ImageOperation {
    return LimitSizeOperation(min: size)
  }
  open var name: String { overrideRequired() }
  open func process(image: UIImage) -> UIImage { overrideRequired() }
  public init() {}
}
open class ImageFormat {
  public static var png: ImageFormat {
    return PngFormat()
  }
  public static var jpg: ImageFormat {
    return JpgFormat(quality: 1.0)
  }
  public static func jpg(_ quality: CGFloat) -> ImageFormat {
    return JpgFormat(quality: quality)
  }
  open var name: String { overrideRequired() }
  open func process(image: UIImage) -> Data { overrideRequired() }
  public init() {}
}

private let thread = NSLock()
private let imageManager = ImageManager()
private class ImageManager {
  private var images = KeyedCache<Image>(capacity: 100, size: 100.mb)
  init() {
    images.purged = purged
    NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: fileQueue) {_ in
      self.memoryWarning()
    }
  }
  
  func purged(image: Image) {
    print("cache: releasing image \(image)")
  }
  
  func updateSize(from: Int, to: Int) {
    images.replace(cacheSize: from, with: to)
  }
  //  func update(image: Image) {
  //    print("updating \(image.url.fileName) \(images.size.bytesStringShort)")
  ////    images.purged = nil
  ////    images[image.url] = nil
  ////    images.purged = purged
  //    images[image.url] = image
  //    print("updated \(image.url.fileName)")
  //  }
  func image(for url: FileURL) -> Image {
    if let image = images[url] {
      return image
    } else {
      let image = Image(url: url)
      images[url] = image
      return image
    }
  }
  func delete(_ url: FileURL) {
    images[url] = nil
  }
  func image(ifContains url: FileURL) -> Image? {
    return images[url]
  }
  func memoryWarning() {
    images.removeAll()
  }
}

private class Image: KeyedCachable, CustomStringConvertible {
  typealias CacheKey = FileURL
  var cacheKey: FileURL { url }
  
  var description: String {
    return "(name: \(url.fileName), size: \(url.fileSize.bytesStringShort), cacheSize: \(cacheSize.bytesStringShort))"
  }
  
  var processed = [String: UIImage]()
  var original: UIImage?
  var url: FileURL
  var runningTasks = 0
  var lastUsed = Time.now
  var cacheSize = 0 {
    didSet {
      imageManager.updateSize(from: oldValue, to: cacheSize)
    }
  }
  
  init(url: FileURL) {
    self.url = url
  }
  
  func set(original: UIImage) {
    thread.lock()
    processed.removeAll()
    self.original = original
    self.cacheSize += original.cacheSize
    thread.unlock()
  }
  func getOriginal(decode: Bool) -> UIImage? {
    thread.lock()
    defer { thread.unlock() }
    if let original = original {
      return original
    } else {
      thread.unlock()
      var original = url.alias.image()
      if decode {
        original = original?.decode4()
      }
      thread.lock()
      if let image = original {
        self.original = image
        self.cacheSize += image.cacheSize
      }
      return original
    }
  }
  func image(completion: @escaping (UIImage) -> ()) {
    assert(Thread.current.isMainThread)
    thread.lock()
    lastUsed = Time.now
    if let image = original {
      thread.unlock()
      completion(image)
    } else {
      runningTasks += 1
      thread.unlock()
      fileQueue.addOperation {
        guard let image = self.getOriginal(decode: true) else { return }
        mainThread {
          completion(image)
        }
        
        thread.lock()
        self.runningTasks -= 1
        thread.unlock()
      }
    }
  }
  func image(with operation: ImageOperation, completion: @escaping (UIImage)->()) {
    assert(Thread.current.isMainThread)
    let name = operation.name
    thread.lock()
    lastUsed = Time.now
    if let image = processed[name] {
      thread.unlock()
      completion(image)
    } else {
      runningTasks += 1
      thread.unlock()
      fileQueue.addOperation {
        thread.lock()
        // ещё раз проверим, вдруг кто-то другой уже успел обработать картинку
        if let image = self.processed[name] {
          thread.unlock()
          mainThread {
            completion(image)
          }
        } else {
          thread.unlock()
          guard let original = self.getOriginal(decode: false) else { return }
          let image = operation.process(image: original)
          thread.lock()
          self.processed[name] = image
          self.cacheSize += image.cacheSize
          thread.unlock()
          mainThread {
            completion(image)
          }
        }
        thread.lock()
        self.runningTasks -= 1
        thread.unlock()
      }
    }
  }
  func hash(into hasher: inout Hasher) {
    url.alias.hash(into: &hasher)
  }
  
  static func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.url.alias == rhs.url.alias
  }
}

private class LimitSizeOperation: ImageOperation {
  override var name: String { "limitSize \(Int(min))" }
  var min: CGFloat
  init(min: CGFloat) {
    self.min = min
  }
  override func process(image: UIImage) -> UIImage {
    return image.limit(minSize: min, false)
  }
}

private class RoundedCornersOperation: ImageOperation {
  override var name: String { "roundedCorners \(Int(size.width)) \(Int(size.height)) \(Int(cornerRadius))" }
  var size: CGSize
  var cornerRadius: CGFloat
  init(size: CGSize, cornerRadius: CGFloat) {
    self.size = size
    self.cornerRadius = cornerRadius
  }
  override func process(image: UIImage) -> UIImage {
    return image.cornerRadius(cornerRadius, size: size)
  }
}

private class ResizeOperation: ImageOperation {
  override var name: String { "resize \(Int(size.width)) \(Int(size.height))" }
  var size: CGSize
  init(size: CGSize) {
    self.size = size
  }
  override func process(image: UIImage) -> UIImage {
    return image.thumbnail(size)
  }
}

private class CircleOperation: ImageOperation {
  override var name: String { "circle \(Int(width))" }
  var width: CGFloat
  init(width: CGFloat) {
    self.width = width
  }
  override func process(image: UIImage) -> UIImage {
    return image.circle(width)
  }
}

private class JpgFormat: ImageFormat {
  override var name: String { "jpg \(quality)" }
  var quality: CGFloat
  init(quality: CGFloat) {
    self.quality = quality
  }
  override func process(image: UIImage) -> Data {
    return image.jpg(quality)
  }
}

private class PngFormat: ImageFormat {
  override var name: String { "png" }
  override func process(image: UIImage) -> Data {
    return image.png()
  }
}
