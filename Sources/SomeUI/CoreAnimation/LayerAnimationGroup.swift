//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/12/2020.
//

#if !os(Linux)
import QuartzCore

//class LayerAnimationGroup<T: CALayer> {
//  let animation = CAAnimationGroup()
//  let layer: T
//  init(layer: T, make: (ObjectAnimation<T>)->([CAAnimation])) {
//    animation.animations = animations
//  }
//  func duration(_ value: CGFloat) -> Self {
//    animation.duration = CFTimeInterval(value)
//    return self
//  }
//  func timing(_ value: CAMediaTimingFunction) -> Self {
//    animation.timingFunction = value
//    return self
//  }
//  func infinity(_ pipe: P<Void>) -> S {
//    animation.repeatCount = .infinity
//    run(.dontSetValue)
//    return pipe.sink { [weak layer, animation] in
//      guard let layer = layer else { return }
//      layer.add(animation, forKey: animation.keyPath ?? "some")
//    }
//  }
//  @discardableResult
//  func run(_ options: RunOptions = .none) -> P<Void> {
//    let pipe = SingleResult<Void>()
//    animation.completion {
//      pipe.send()
//    }
//    switch options {
//    case .none:
//      layer.setValue(animation.toValue, forKey: key)
//    case .dontSetValue:
//      break
//    }
//    layer.add(animation, forKey: key)
//    return pipe
//  }
//  func cancel() {
//    layer.removeAnimation(forKey: key)
//  }
//}


#endif
