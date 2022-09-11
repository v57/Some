//
//  File.swift
//  
//
//  Created by Дмитрий Козлов on 05.02.2021.
//

#if canImport(UIKit)
import UIKit
import Some

public class DismissGesture: UIPanGestureRecognizer, PipeStorage {
  public static var isScreenEdgePan: Bool = false
  public static var velocity: CGPoint?
  public static var duration: CGFloat { 0.37 }
  public static func updateTime(velocity: CGFloat, height: CGFloat, scrolled: CGFloat, time: CGFloat) -> Double {
    Double(min(duration, ((height - scrolled) / height) * duration, velocity > 0 ? (height - scrolled) / velocity : time))
  }
  public static func updateTime(height: CGFloat, scrolled: CGFloat, time: CGFloat) -> Double {
    Double(min(duration, ((height - scrolled) / height) * duration, (velocity?.y ?? 1) > 0 ? (height - scrolled) / (velocity?.y ?? 1) : time))
  }
  public static func updateTime(velocity: CGFloat, width: CGFloat, scrolled: CGFloat, time: CGFloat) -> Double {
    Double(min(duration, ((width - scrolled) / width) * duration, velocity > 0 ? (width - scrolled) / velocity : time))
  }
  public static func updateTime(width: CGFloat, scrolled: CGFloat, time: CGFloat) -> Double {
    Double(min(duration, ((width - scrolled) / width) * duration, (velocity?.x ?? 1) > 0 ? (width - scrolled) / (velocity?.x ?? 1) : time))
  }
  public var pipes: Set<C> = []
  var dismissalPanGesture: UIPanGestureRecognizer { self }
  private lazy var dismissalScreenEdgePanGesture: HorizontalDismissGesture = {
    let pan = HorizontalDismissGesture()
    pan.edges = .left
    return pan
  }()
  
  
  weak var viewController: UIViewController!
  var vertical: Bool
  var horizontal: Bool
  public init(vertical: Bool, horizontal: Bool) {
    self.vertical = vertical
    self.horizontal = horizontal
    super.init(target: nil, action: nil)
  }
  public func add(to viewController: UIViewController) {
    self.viewController = viewController
    let view = viewController.view!
    

    if vertical {
      dismissalPanGesture.addTarget(self, action: #selector(pan(gesture:)))
      dismissalPanGesture.delegate = self
      dismissalPanGesture.require(toFail: dismissalScreenEdgePanGesture)
    }
    view.addGestureRecognizer(dismissalPanGesture)
    if horizontal {
      dismissalScreenEdgePanGesture.addTarget(self, action: #selector(pan(gesture:)))
      dismissalScreenEdgePanGesture.delegate = self
      view.addGestureRecognizer(dismissalScreenEdgePanGesture)
    }
    draggingDownToDismiss = true
  }
  var draggingDownToDismiss = false
  func didSuccessfullyDragDownToDismiss(isScreenEdgePan: Bool, velocity: CGPoint?) {
    DismissGesture.velocity = velocity
    DismissGesture.isScreenEdgePan = isScreenEdgePan
    viewController.dismiss(animated: true) {
      self.scrollViews.removeAll()
      self.viewController?.view.removeGestureRecognizer(self)
    }
  }
  
  func userWillCancelDissmissalByDraggingToTop(velocityY: CGFloat) {}
  
  func didCancelDismissalTransition() {
    // Clean up
    interactiveStartingPoint = nil
    draggingDownToDismiss = false
    self.progress = 0
    UIView.animate(withDuration: 0.15) {
      self.view?.transform = .init(translationX: 0, y: 0)
    }
  }
  var interactiveStartingPoint: CGPoint?
  var scrollViews = Set<UIScrollView>()
  
  var progress: CGFloat = 0
}

private extension UIScrollView {
  var offsetY: CGFloat {
    get { contentOffset.y + contentInset.top }
    set { contentOffset.y = newValue - contentInset.top }
  }
}

extension DismissGesture: UIScrollViewDelegate {
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard vertical else { return }
    if draggingDownToDismiss || (scrollView.isTracking && scrollView.offsetY < 0) {
      if scrollView.offsetY > 0 && progress == 0 {
        draggingDownToDismiss = false
      } else {
        draggingDownToDismiss = true
        scrollView.offsetY = 0
      }
    }
  }
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if velocity.y > 0 && scrollView.offsetY < 0 {
      scrollView.offsetY = 0
    }
  }
}
extension DismissGesture {
  @objc func pan(gesture: UIPanGestureRecognizer) {
    let isScreenEdgePan = gesture.isKind(of: UIScreenEdgePanGestureRecognizer.self)
    guard draggingDownToDismiss || isScreenEdgePan else { return }
    
    if isScreenEdgePan {
      let startingPoint: CGPoint
      
      if let p = interactiveStartingPoint {
        startingPoint = p
      } else {
        // Initial location
        startingPoint = gesture.location(in: nil)
        interactiveStartingPoint = startingPoint
      }
      
      
      let currentLocation = gesture.location(in: nil)
      let progress = (currentLocation.x - startingPoint.x) / 100
      
      switch gesture.state {
      case .began:
        if let view = self.view {
          func fr(view: UIView) -> UIView? {
            if view.isFirstResponder {
              return view
            } else {
              for view in view.subviews {
                if let v = fr(view: view) {
                  return v
                }
              }
            }
            return nil
          }
          fr(view: view)?.resignFirstResponder()
        }
      case .changed:
        let actualProgress = max(0, min(progress, 10))
        self.progress = actualProgress
        
        self.view?.transform = .offset(currentLocation.x - startingPoint.x, 0)
      case .ended:
        let velocity = gesture.velocity(in: nil)
        let shouldCancel: Bool
        if velocity.x.magnitude > 100 && velocity.y.magnitude > velocity.x.magnitude {
          shouldCancel = true
        } else if velocity.x / 2 + currentLocation.x - startingPoint.x > 100 {
          shouldCancel = false
        } else {
          shouldCancel = true
        }
        if shouldCancel {
          didCancelDismissalTransition()
        } else {
          didSuccessfullyDragDownToDismiss(isScreenEdgePan: isScreenEdgePan, velocity: velocity)
        }
      case .cancelled:
        didCancelDismissalTransition()
      default: return
      }
    } else {
      let startingPoint: CGPoint
      if let p = interactiveStartingPoint {
        startingPoint = p
      } else {
        // Initial location
        startingPoint = gesture.location(in: nil)
        interactiveStartingPoint = startingPoint
      }
      
      
      let currentLocation = gesture.location(in: nil)
      let progress = (currentLocation.y - startingPoint.y) / 100
      
      switch gesture.state {
      case .began: break
      case .changed:
        let actualProgress = progress.limit(in: 0..<10)
        self.progress = actualProgress
        self.view?.transform = .init(translationX: 0, y: actualProgress*100)
      case .ended:
        let velocity = gesture.velocity(in: nil)
        let shouldCancel: Bool
        if velocity.y.magnitude > 100 && velocity.x.magnitude > velocity.y.magnitude {
          shouldCancel = true
        } else if velocity.y / 2 + currentLocation.y - startingPoint.y > 100 {
          shouldCancel = false
        } else {
          shouldCancel = true
        }
        if shouldCancel {
          didCancelDismissalTransition()
        } else {
          didSuccessfullyDragDownToDismiss(isScreenEdgePan: isScreenEdgePan, velocity: velocity)
        }
      case .cancelled:
        didCancelDismissalTransition()
      default: return
      }
    }
  }
}

// MARK:- Gesture delegate
extension DismissGesture: UIGestureRecognizerDelegate {
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let view = otherGestureRecognizer.view as? UIScrollView else { return true }
    if view.delegate == nil {
      view.delegate = self
    } else {
      if let scrollView = view as? PScrollView, scrollViews.insert(scrollView).inserted {
//        scrollView.panGestureRecognizer.require(toFail: dismissalScreenEdgePanGesture)
        scrollView.pipe.didScroll.sink { [unowned self] in
          self.scrollViewDidScroll($0)
        }.store(in: self)
        scrollView.pipe.willEndDragging.sink { [unowned self] scrollView, velocity, offset in
          self.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: offset)
        }.store(in: self)
      }
    }
    return true
  }
}

class HorizontalDismissGesture: UIScreenEdgePanGestureRecognizer {
  override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if otherGestureRecognizer is UIPanGestureRecognizer && !(otherGestureRecognizer is DismissGesture) {
      return true
    } else {
      return false
    }
  }
}
#endif
