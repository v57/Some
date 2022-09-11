//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/12/2020.
//

#if !os(Linux)
import QuartzCore

public struct ObjectAnimation<T: AnyObject> {
  public var parent: T
  public init(_ parent: T) {
    self.parent = parent
  }
}
/// A type that has reactive extensions.
public protocol ObjectAnimationProtocol: AnyObject {
  associatedtype AnimationBase: AnyObject
  var animate: ObjectAnimation<AnimationBase> { get }
}
public extension ObjectAnimationProtocol {
  var animate: ObjectAnimation<Self> { ObjectAnimation(self) }
}
extension NSObject: ObjectAnimationProtocol { }

public protocol LayerAnimatorPath {
  var keyPath: String { get }
  func makeAnimation(for layer: CALayer) -> CAPropertyAnimation
}
public extension ObjectAnimation where T: CALayer {
  var layer: CALayer { parent }
  var anchorPoint: LayerPath<CGPoint> { LayerPath(layer, "anchorPoint") }
  var anchorPointZ: LayerPath<CGFloat> { LayerPath(layer, "anchorPointZ") }
  var backgroundColor: LayerPath<CGColor> { LayerPath(layer, "backgroundColor") }
  var backgroundFilters: LayerPath<[Any]> { LayerPath(layer, "backgroundFilters") }
  var borderColor: LayerPath<CGColor> { LayerPath(layer, "borderColor") }
  var borderWidth: LayerPath<CGFloat> { LayerPath(layer, "borderWidth") }
  var bounds: LayerPath<CGRect> { LayerPath(layer, "bounds") }
  var compositingFilter: LayerPath<Any> { LayerPath(layer, "compositingFilter") }
  var contents: LayerPath<Any> { LayerPath(layer, "contents") }
  var contentsScale: LayerPath<CGFloat> { LayerPath(layer, "contentsScale") }
  var contentsCenter: LayerPath<CGRect> { LayerPath(layer, "contentsCenter") }
  var contentsRect: LayerPath<CGRect> { LayerPath(layer, "contentsRect") }
  var cornerRadius: LayerPath<CGFloat> { LayerPath(layer, "cornerRadius") }
  var isDoubleSided: LayerPath<Bool> { LayerPath(layer, "isDoubleSided") } // or double sided
  var filters: LayerPath<[Any]> { LayerPath(layer, "filters") }
  var frame: LayerPath<CGRect> { LayerPath(layer, "frame") }
  var isHidden: LayerPath<Bool> { LayerPath(layer, "isHidden") } // or hidden
  var mask: LayerPath<CALayer> { LayerPath(layer, "mask") }
  var masksToBounds: LayerPath<Bool> { LayerPath(layer, "masksToBounds") }
  var opacity: LayerPath<Float> { LayerPath(layer, "opacity") }
  var shadowColor: LayerPath<CGColor> { LayerPath(layer, "shadowColor") }
  var shadowOffset: LayerPath<CGSize> { LayerPath(layer, "shadowOffset") }
  var shadowOpacity: LayerPath<Float> { LayerPath(layer, "shadowOpacity") }
  var shadowPath: LayerPath<CGPath> { LayerPath(layer, "shadowPath") }
  var shadowRadius: LayerPath<CGFloat> { LayerPath(layer, "shadowRadius") }
  var sublayers: LayerPath<[CALayer]> { LayerPath(layer, "sublayers") }
  var sublayerTransform: LayerPath<CATransform3D> { LayerPath(layer, "sublayerTransform") }
  var transform: LayerPath<CATransform3D> { LayerPath(layer, "transform") }
  var position: LayerPath<CGPoint> { LayerPath(layer, "position") }
  var zPosition: LayerPath<CGFloat> { LayerPath(layer, "zPosition") }
  var minificationFilterBias: LayerPath<Float> { LayerPath(layer, "minificationFilterBias") }
  var shouldRasterize: LayerPath<Bool> { LayerPath(layer, "shouldRasterize") }
  var rasterizationScale: LayerPath<CGFloat> { LayerPath(layer, "rasterizationScale") }
}
public extension ObjectAnimation where T: CAShapeLayer {
  var path: LayerPath<CGPath> { LayerPath(layer, "path") }
  var fillColor: LayerPath<CGColor> { LayerPath(layer, "fillColor") }
  var lineDashPhase: LayerPath<CGFloat> { LayerPath(layer, "lineDashPhase") }
  var lineWidth: LayerPath<CGFloat> { LayerPath(layer, "lineWidth") }
  var miterLimit: LayerPath<CGFloat> { LayerPath(layer, "miterLimit") }
  var strokeColor: LayerPath<CGColor> { LayerPath(layer, "strokeColor") }
  var strokeStart: LayerPath<CGFloat> { LayerPath(layer, "strokeStart") }
  var strokeEnd: LayerPath<CGFloat> { LayerPath(layer, "strokeEnd") }
}
public extension ObjectAnimation where T: CATextLayer {
  var fontSize: LayerPath<CGFloat> { LayerPath(layer, "fontSize") }
  var foregroundColor: LayerPath<CGColor> { LayerPath(layer, "foregroundColor") }
}
public extension ObjectAnimation where T: CAReplicatorLayer {
  var instanceCount: LayerPath<Int> { LayerPath(layer, "instanceCount") }
  var instanceDelay: LayerPath<CFTimeInterval> { LayerPath(layer, "instanceDelay") }
  var instanceTransform: LayerPath<CATransform3D> { LayerPath(layer, "instanceTransform") }
  var instanceColor: LayerPath<CGColor> { LayerPath(layer, "instanceColor") }
  var instanceRedOffset: LayerPath<Float> { LayerPath(layer, "instanceRedOffset") }
  var instanceGreenOffset: LayerPath<Float> { LayerPath(layer, "instanceGreenOffset") }
  var instanceBlueOffset: LayerPath<Float> { LayerPath(layer, "instanceBlueOffset") }
  var instanceAlphaOffset: LayerPath<Float> { LayerPath(layer, "instanceAlphaOffset") }
}
public extension ObjectAnimation where T: CAGradientLayer {
  var colors: LayerPath<[CGColor]> { LayerPath(layer, "colors") }
  var locations: LayerPath<[CGFloat]> { LayerPath(layer, "locations") }
  var startPoint: LayerPath<CGPoint> { LayerPath(layer, "startPoint") }
  var endPoint: LayerPath<CGPoint> { LayerPath(layer, "endPoint") }
}
public extension ObjectAnimation where T: CAEmitterLayer {
  var birthRate: LayerPath<Float> { LayerPath(layer, "birthRate") }
  var lifetime: LayerPath<Float> { LayerPath(layer, "lifetime") }
  var emitterPosition: LayerPath<CGPoint> { LayerPath(layer, "emitterPosition") }
  var emitterZPosition: LayerPath<CGFloat> { LayerPath(layer, "emitterZPosition") }
  var emitterSize: LayerPath<CGSize> { LayerPath(layer, "emitterSize") }
  var emitterDepth: LayerPath<CGFloat> { LayerPath(layer, "emitterDepth") }
  var velocity: LayerPath<Float> { LayerPath(layer, "velocity") }
  var scale: LayerPath<Float> { LayerPath(layer, "scale") }
  var spin: LayerPath<Float> { LayerPath(layer, "spin") }
}
public extension ObjectAnimation where T: CATiledLayer {
  var tileSize: LayerPath<CGSize> { LayerPath(layer, "tileSize") }
}

public extension LayerPath where T == CATransform3D {
  var rotationX: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".rotation.x") }
  var rotationY: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".rotation.y") }
  var rotationZ: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".rotation.z") }
  var rotation: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".rotation") }
  var scaleX: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".scale.x") }
  var scaleY: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".scale.y") }
  var scaleZ: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".scale.z") }
  var scale: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".scale") }
  var translationX: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".translation.x") }
  var translationY: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".translation.y") }
  var translationZ: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".translation.z") }
}
public extension LayerPath where T == CGPoint {
  var x: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".x") }
  var y: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".y") }
}

public extension LayerPath where T == CGSize {
  var width: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".width") }
  var height: LayerPath<CGFloat> { LayerPath<CGFloat>(layer, keyPath+".height") }
}
public extension LayerPath where T == CGRect {
  var origin: LayerPath<CGPoint> { LayerPath<CGPoint>(layer, keyPath+".origin") }
  var size: LayerPath<CGSize> { LayerPath<CGSize>(layer, keyPath+".size") }
}


#endif
