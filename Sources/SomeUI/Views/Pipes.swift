#if os(iOS)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 5/15/20.
//

import UIKit
import Some

public struct ViewData {
  public var pipes: Set<S> = []
  public var size: CGSize = .zero
}
public extension ViewData {
  mutating func layoutSubviews<View: ViewDataProtocol>(_ view: View) {
    guard view.frame.size != size else { return }
    size = view.frame.size
    view.sizeChanged()
  }
}
/**
 Implementation:
 ```
 class View: UIView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
 }
 ```
 */
public protocol ViewDataProtocol: UIView, PipeStorage {
  var viewData: ViewData { get set }
  func sizeChanged()
}
public extension ViewDataProtocol {
  var pipes: Set<S> {
    get { viewData.pipes }
    set { viewData.pipes = newValue }
  }
}

public typealias PEmptyView = PStackView
open class PView: UIView, ViewDataProtocol {
  public var viewData = ViewData()
  public override init(frame: CGRect = .zero) {
    super.init(frame: frame)
  }
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
}
open class PImageView: UIImageView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
  public var pipe: P<UIImage>? {
    get { nil }
    set { newValue?.assign(self, \.image).store(in: self) }
  }
}
open class PStackView: UIStackView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
}
open class PLabel: UILabel, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
}
open class PTextField: UITextField, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
}
open class PTextView: UITextView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
}
open class PViewController: UIViewController, PipeStorage {
  public var pipes: Set<S> = []
}
open class PScrollView: UIScrollView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open func sizeChanged() {}
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
