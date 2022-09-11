#if canImport(UIKit)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 9/10/20.
//

import UIKit

public enum Shapes {
  
}

public struct ShadowLayer {
  fileprivate var layer: CALayer
  fileprivate var data: ShapeData
  @discardableResult
  public func offsetX(_ offset: CGFloat) -> Self {
    layer.shadowOffset.width = offset * data.scale
    return self
  }
  @discardableResult
  public func offsetY(_ offset: CGFloat) -> Self {
    layer.shadowOffset.height = offset * data.scale
    return self
  }
  @discardableResult
  public func radius(_ radius: CGFloat) -> Self {
    layer.shadowRadius = radius * data.scale
    return self
  }
  @discardableResult
  public func color(_ color: UIColor) -> Self {
    layer.shadowColor = color.cgColor
    return self
  }
  @discardableResult
  public func alpha(_ alpha: CGFloat) -> Self {
    layer.shadowOpacity = Float(alpha)
    return self
  }
  @discardableResult
  public func path(_ path: CGPath) -> Self {
    layer.shadowPath = path
    return self
  }
  fileprivate func done() {
    var frame = CGRect(origin: .zero, size: data.size)
    frame.origin.x -= layer.shadowRadius + layer.shadowOffset.width
    frame.origin.y -= layer.shadowRadius + layer.shadowOffset.height
    frame.size.width += layer.shadowRadius * 2
    frame.size.height += layer.shadowRadius * 2
    let path = UIBezierPath(rect: frame)
    path.append(data.path.reversing())
    layer.shadowPath = path.cgPath
  }
}

public struct GradientLayer {
  fileprivate var layer: CAGradientLayer
  fileprivate var data: ShapeData
  @discardableResult
  public func colors(_ colors: UIColor...) -> Self {
    layer.colors = colors.map(\.cgColor)
    return self
  }
  @discardableResult
  public func colors(_ colors: UInt64...) -> Self {
    layer.colors = colors.map { UIColor.hex($0).cgColor }
    return self
  }
  @discardableResult
  public func positions(_ positions: CGFloat...) -> Self {
    layer.locations = positions.map { NSNumber(floatLiteral: Double($0)) }
    return self
  }
  @discardableResult
  public func from(_ startPoint: CGPoint) -> Self {
    layer.startPoint = startPoint
    return self
  }
  @discardableResult
  public func to(_ endPoint: CGPoint) -> Self {
    layer.endPoint = endPoint
    return self
  }
  @discardableResult
  public func type(_ type: CAGradientLayerType) -> Self {
    layer.type = type
    return self
  }
}

class ShapeData {
  let path: UIBezierPath
  let cgPath: CGPath
  let size: CGSize
  var scale: CGFloat = 1
  func makeMask() -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.path = cgPath
    return layer
  }
  lazy var inverted: UIBezierPath = {
    let path = UIBezierPath(rect: CGRect(origin: .zero, size: size))
    path.append(self.path.reversing())
    return path
  }()
  init(_ path: UIBezierPath) {
    self.path = path
    cgPath = path.cgPath
    size = cgPath.boundingBoxOfPath.size
  }
  init(_ path: UIBezierPath, scale: CGFloat) {
    path.apply(CGAffineTransform(scaleX: scale, y: scale))
    self.scale = scale
    self.path = path
    cgPath = path.cgPath
    size = cgPath.boundingBoxOfPath.size
  }
}
public class ShapeGroup {
  
  public let layer = CALayer()
  let data: ShapeData
  
  var cgPath: CGPath { data.cgPath }
  var size: CGSize { data.size }
  var lastMask: CALayer {
    recursiveLast(layer, \.mask)
  }
  
  public init(_ path: UIBezierPath) {
    self.data = ShapeData(path)
    layer.frame.size = data.size
  }
  init(_ data: ShapeData) {
    self.data = data
    layer.frame.size = data.size
  }
  
  @discardableResult
  public func group(_ build: (ShapeGroup)->()) -> Self {
    let group = ShapeGroup(data)
    build(group)
    layer.addSublayer(group.layer)
    return self
  }
  
  public func shadow() -> ShadowLayer {
    let layer = CALayer()
    layer.frame.size = size
    self.layer.addSublayer(layer)
    return ShadowLayer(layer: layer, data: data).path(data.cgPath).alpha(1).offsetX(0).offsetY(0)
  }
  public func innerShadow(_ build: (ShadowLayer)->()) {
    let layer = CALayer()
    layer.mask = data.makeMask()
    self.layer.addSublayer(layer)
    let shadow = ShadowLayer(layer: layer, data: data).alpha(1).offsetX(0).offsetY(0)
    build(shadow)
    shadow.done()
  }
  private func shape() -> CAShapeLayer {
    let layer = CAShapeLayer()
    layer.path = cgPath
    return layer
  }
  public func fillInverted(_ color: UIColor) {
    let layer = CAShapeLayer()
    layer.path = data.inverted.cgPath
    layer.fillColor = color.cgColor
    self.layer.addSublayer(layer)
  }
  
  public func fill(_ color: UIColor) {
    let layer = CAShapeLayer()
    layer.path = cgPath
    layer.fillColor = color.cgColor
    self.layer.addSublayer(layer)
  }
  public func fill(_ color: UInt64) {
    let layer = CAShapeLayer()
    layer.path = cgPath
    layer.fillColor = UIColor.hex(color).cgColor
    self.layer.addSublayer(layer)
  }
  public func gradient() -> GradientLayer {
    let layer = CAGradientLayer()
    layer.frame.size = size
    layer.mask = data.makeMask()
    self.layer.addSublayer(layer)
    return GradientLayer(layer: layer, data: data)
  }
  @discardableResult
  public func offsetX(_ offset: CGFloat) -> Self {
    layer.frame.origin.x = offset * data.scale
    return self
  }
  @discardableResult
  public func offsetY(_ offset: CGFloat) -> Self {
    layer.frame.origin.y = offset * data.scale
    return self
  }
  @discardableResult
  public func rotate(_ degrees: CGFloat) -> Self {
    let angle = degrees / 180 * .pi
    layer.transform = CATransform3DRotate(layer.transform, angle, 0, 0, 1)
    return self
  }
}

public extension UIBezierPath {
  func shape() -> ShapeGroup {
    ShapeGroup(self)
  }
  @discardableResult
  func shape(scale: CGFloat = 1, _ build: (ShapeGroup)->()) -> ShapeGroup {
    let group = scale == 1 ? ShapeGroup(self) : ShapeGroup(ShapeData(self, scale: scale))
    build(group)
    return group
  }
}

// MARK:- Dynamic Layer View
open class DynamicLayerView<T>: PView {
  public var currentLayer: CALayer!
  public let makeLayer: (T)->(CALayer)
  public var size: CGSize? {
    didSet {
      guard let size = size else { return }
      guard oldValue == nil else { return }
      build().w(size.width).h(size.height)
    }
  }
  public init(_ item: T, size: CGSize? = nil, _ makeLayer: @escaping (T)->(CALayer)) {
    self.makeLayer = makeLayer
    super.init(frame: .zero)
    currentLayer = makeLayer(item)
    layer.addSublayer(currentLayer)
    set(size: size)
  }
  public init(_ item: P<T>, size: CGSize? = nil, _ makeLayer: @escaping (T)->(CALayer)) {
    self.makeLayer = makeLayer
    super.init(frame: .zero)
    set(size: size)
    item.call(self, DynamicLayerView<T>.update)
  }
  public init(size: CGSize? = nil, _ makeLayer: @escaping (T)->(CALayer)) {
    self.makeLayer = makeLayer
    super.init(frame: .zero)
    set(size: size)
  }
  public required init(coder: NSCoder) { fatalError() }
  open override func sizeChanged() {
    super.sizeChanged()
    guard let layer = currentLayer else { return }
    layer.center = bounds.center
  }
  func set(size: CGSize?) {
    self.size = size
  }
  open func update(item: T) {
    let layer = makeLayer(item)
    self.layer.addSublayer(layer)
    currentLayer?.removeFromSuperlayer()
    currentLayer = layer
    set(size: layer.frame.size)
    if frame.size != .zero {
      layer.center = bounds.center
    }
  }
}
extension CALayer {
  var center: CGPoint {
    get { frame.center }
    set {
      temp(&transform, .default) {
        frame.center = newValue
      }
    }
  }
}

extension CATransform3D {
  static var `default`: Self {
    CATransform3D(m11: 1.0, m12: 0.0, m13: 0.0, m14: 0.0, m21: 0.0, m22: 1.0, m23: 0.0, m24: 0.0, m31: 0.0, m32: 0.0, m33: 1.0, m34: 0.0, m41: 0.0, m42: 0.0, m43: 0.0, m44: 1.0)
  }
}

#endif
