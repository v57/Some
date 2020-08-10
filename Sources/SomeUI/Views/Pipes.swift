#if os(iOS)
//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 5/15/20.
//

import UIKit
import SomeFunctions

public typealias PEmptyView = PStackView
open class PView: UIView, PipeStorage {
  public var pipes: Set<S> = []
}
open class PImageView: UIImageView, PipeStorage {
  public var pipes: Set<S> = []
  public var pipe: P<UIImage>? {
    get { nil }
    set { newValue?.assign(self, \.image).store(in: self) }
  }
}
open class PStackView: UIStackView, PipeStorage {
  public var pipes: Set<S> = []
}
open class PLabel: UILabel, PipeStorage {
  public var pipes: Set<S> = []
}
open class PTextField: UITextField, PipeStorage {
  public var pipes: Set<S> = []
}
open class PTextView: UITextView, PipeStorage {
  public var pipes: Set<S> = []
}
open class PViewController: UIViewController, PipeStorage {
  public var pipes: Set<S> = []
}
open class PScrollView: UIScrollView, PipeStorage {
  public var pipes: Set<S> = []
  public lazy var pipe: Delegate = {
    let delegate = Delegate()
    self.delegate = delegate
    return delegate
  }()
}

extension UIImageView: PipeReceiver {
  public func receivedInput(_ value: UIImage?) {
    self.image = value
  }
}



extension PScrollView {
  public class Delegate: NSObject, UIScrollViewDelegate {
    @Lazy public var didScroll = P<UIScrollView>()
    @Lazy public var didZoom = P<UIScrollView>()
    @Lazy public var willBeginDragging = P<UIScrollView>()
    @Lazy public var willEndDragging = P<(scrollView: UIScrollView, velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)>()
    @Lazy public var didEndDragging = P<(scrollView: UIScrollView, decelerate: Bool)>()
    @Lazy public var willBeginDecelerating = P<UIScrollView>()
    @Lazy public var didEndDecelerating = P<UIScrollView>()
    @Lazy public var didEndScrollingAnimation = P<UIScrollView>()
    public var shouldScrollToTop: ((UIScrollView) -> Bool)?
    @Lazy public var didScrollToTop = P<UIScrollView>()
    @Lazy public var didChangeAdjustedContentInset = P<UIScrollView>()
    public var zooming: ((UIScrollView)->UIView?)?
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
      $didScroll?.send(scrollView)
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
      $didZoom?.send(scrollView)
    }
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      $willBeginDragging?.send(scrollView)
    }
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
      $willEndDragging?.send((scrollView, velocity, targetContentOffset))
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      $didEndDragging?.send((scrollView, decelerate))
    }
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
      $willBeginDecelerating?.send(scrollView)
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      $didEndDecelerating?.send(scrollView)
    }
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
      $didEndScrollingAnimation?.send(scrollView)
    }
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      zooming?(scrollView)
    }
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
      shouldScrollToTop?(scrollView) ?? true
    }
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
      $didScrollToTop?.send(scrollView)
    }
    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
      $didChangeAdjustedContentInset?.send(scrollView)
    }
  }
}
#endif
