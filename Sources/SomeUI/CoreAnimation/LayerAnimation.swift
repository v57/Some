//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/12/2020.
//

#if !os(Linux)
import QuartzCore
import Some


public struct LayerPath<T> {
  public var builder: LayerAnimation<T> { .init(self) }
  
  public let keyPath: String
  public let layer: CALayer
  
  public init(_ layer: CALayer, _ keyPath: String) {
    self.layer = layer
    self.keyPath = keyPath
  }
}
public protocol AnyLayerAnimation {
  var caAnimation: CAAnimation { get }
}
extension SomeSettings {
  public enum Animation {
    public static var allowsInfinityAnimations = true
  }
}
public class LayerAnimation<T>: AnyLayerAnimation {
  public var caAnimation: CAAnimation { animation }
  public let path: LayerPath<T>
  public let animation: CABasicAnimation
  public init(_ path: LayerPath<T>) {
    self.path = path
    animation = CABasicAnimation(keyPath: path.keyPath)
  }
  
  public enum RunOptions {
    case none, dontSetValue
  }
  public enum TimeOffsetOptions {
    case normal, random, seed, sync
  }
}

public extension LayerAnimation {
  private var layer: CALayer { path.layer }
  private var key: String { path.keyPath }
  
  func duration(_ value: CGFloat) -> Self {
    animation.duration = CFTimeInterval(value)
    return self
  }
  func offset(_ options: TimeOffsetOptions) -> Self {
    switch options {
    case .normal:
      break
    case .random:
      animation.beginTime = CACurrentMediaTime() - .random(in: 0..<animation.duration)
    case .seed:
      var generator = SomeRandomNumberGenerator("animation-\(ObjectIdentifier(layer))")
      animation.beginTime = CACurrentMediaTime() - .random(in: 0..<animation.duration, using: &generator)
    case .sync:
      animation.beginTime = 0
    }
    return self
  }
  func time(_ value: Range<CGFloat>) -> Self {
    animation.beginTime = CFTimeInterval(value.lowerBound)
    animation.duration = CFTimeInterval(value.upperBound - value.lowerBound)
    return self
  }
  func timing(_ value: CAMediaTimingFunction) -> Self {
    animation.timingFunction = value
    return self
  }
  func from(_ value: T) -> Self {
    animation.fromValue = value
    return self
  }
  func fromCurrent() -> Self {
    animation.fromValue = (layer.presentation() ?? layer).value(forKey: key)
    return self
  }
  func to(_ value: T) -> Self {
    animation.toValue = value
    return self
  }
  func cancelOnCompletion(_ removed: Bool) -> Self {
    animation.isRemovedOnCompletion = removed
    return self
  }
  func by(_ value: T) -> Self {
    animation.byValue = value
    return self
  }
  func autoreverse() -> Self {
    animation.autoreverses = true
    return self
  }
  func infinity(_ pipe: P<Void>) -> S {
    if SomeSettings.Animation.allowsInfinityAnimations {
      animation.repeatCount = .infinity
    }
    run(.dontSetValue)
    return pipe.forEach { [weak layer, animation] in
      guard let layer = layer else { return }
      layer.add(animation, forKey: animation.keyPath ?? "some")
    }
  }
  @discardableResult
  func run(_ options: RunOptions = .none) -> P<Void> {
    let pipe = SingleResult<Void>()
    #if canImport(UIKit)
    animation.completion {
      pipe.send()
    }
    #endif
    switch options {
    case .none:
      layer.setValue(animation.toValue, forKey: key)
    case .dontSetValue:
      break
    }
    layer.add(animation, forKey: key)
    return pipe
  }
  func cancel() {
    layer.removeAnimation(forKey: key)
  }
}

public extension CAAnimation {
  func runInfinity(name: String, on layer: CALayer, _ pipe: P<Void>) -> S {
    if SomeSettings.Animation.allowsInfinityAnimations {
      repeatCount = .infinity
    }
    layer.add(self, forKey: name)
    return pipe.forEach { [weak layer, self] in
      guard let layer = layer else { return }
      layer.add(self, forKey: name)
    }
  }
}

public extension LayerPath {
  func from(_ value: T) -> LayerAnimation<T> {
    builder.from(value)
  }
  func fromCurrent() -> LayerAnimation<T> {
    return builder.fromCurrent()
  }
  func to(_ value: T) -> LayerAnimation<T> {
    builder.to(value)
  }
  func by(_ value: T) -> LayerAnimation<T> {
    builder.by(value)
  }
}

#endif
