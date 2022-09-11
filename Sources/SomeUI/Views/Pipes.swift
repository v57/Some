#if os(iOS)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 5/15/20.
//

import UIKit
import Some

// MARK:- ViewData
public class ViewData {
  public var pipes: Set<C> = []
  public let layoutSubviews = P<Void>()
  public init() { }
  @Published public var size: CGSize = .zero
  @V public var window: UIWindow?
  @Published public var traitCollection: UITraitCollection?
  public func set(traitCollection: UITraitCollection) {
    if #available(iOS 12.0, *) {
      if traitCollection.userInterfaceStyle != self.traitCollection?.userInterfaceStyle {
        self.traitCollection = traitCollection
      }
    }
  }
}
public extension ViewData {
  func layoutSubviews<View: ViewDataProtocol>(_ view: View) {
    layoutSubviews.send()
    guard view.frame.size != size else { return }
    CALayer.noAnimation {
      size = view.frame.size
    }
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
  var pipes: Set<C> {
    get { viewData.pipes }
    set { viewData.pipes = newValue }
  }
  func darkModeChanged(_ action: @escaping ()->()) {
    viewData.$traitCollection.sink { _ in
      action()
    }.store(in: self)
  }
  func setColor<T>(_ color: UIColor, for view: T, _ keyPath: ReferenceWritableKeyPath<T, CGColor?>) {
    viewData.$traitCollection.sink { _ in
      view[keyPath: keyPath] = color.cgColor
    }.store(in: self)
  }
}

public typealias PEmptyView = PStackView
// MARK:- PView
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
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    if viewData.window != window {
      viewData.window = window
    }
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
}
// MARK:- PImageView
open class PImageView: UIImageView, ViewDataProtocol {
  public var viewData = ViewData()
  public var imageBag = SingleItemBag()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
  public var pipe: P<UIImage>? {
    get { nil }
    set { newValue?.assign(self, \.image).store(in: imageBag) }
  }
  open func image<P: Publisher>(_ publisher: P) -> Self
  where P.Output == UIImage, P.Failure == Never {
    publisher.sink { [unowned self] image in
      self.image = image
    }.store(in: imageBag)
    return self
  }
  open func image<P: Publisher>(_ publisher: P) -> Self
  where P.Output == UIImage?, P.Failure == Never {
    publisher.sink { [unowned self] image in
      self.image = image
    }.store(in: imageBag)
    return self
  }
  open func image<P: Publisher>(_ publisher: P, clearOnError: Bool) -> Self
  where P.Output == UIImage {
    publisher.sink { [unowned self] completion in
      switch completion {
      case .finished: break
      case .failure:
        if clearOnError {
          self.image = nil
        }
      }
    } receiveValue: { [unowned self] image in
      self.image = image
    }.store(in: imageBag)
    return self
  }
  open func image<P: Publisher>(_ publisher: P, clearOnError: Bool) -> Self
  where P.Output == UIImage? {
    publisher.sink { [unowned self] completion in
      switch completion {
      case .finished: break
      case .failure:
        if clearOnError {
          self.image = nil
        }
      }
    } receiveValue: { [unowned self] image in
      self.image = image
    }.store(in: imageBag)
    return self
  }
}
// MARK:- PStackView
open class PStackView: UIStackView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
}
// MARK:- PLabel
open class PLabel: UILabel, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
}
// MARK:- PTextField
open class PTextField: UITextField, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
}
// MARK:- PTextView
open class PTextView: UITextView, ViewDataProtocol {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
  }
  open func sizeChanged() {}
}
// MARK:- PViewController
open class PViewController: UIViewController, PipeStorage {
  public var pipes: Set<C> = []
//  static let closed = P<UIViewController>()
//  static let opened = P<UIViewController>()
//
//  static let viewWillAppear = P<UIViewController>()
//  static let viewDidAppear = P<UIViewController>()
//  static let viewWillDisappear = P<UIViewController>()
//  static let viewDidDisappear = P<UIViewController>()
//  static let willDeinit = P<UIViewController>()
//
//  var onClose: E { ViewControllerEvents.closed.filter(self) }
//  var onOpen: E { ViewControllerEvents.opened.filter(self) }
//
//  deinit {
//    ViewControllerEvents.willDeinit.send(self)
//  }
//
//  override func firstAppear() {
//    super.firstAppear()
//    ViewControllerEvents.opened.send(self)
//  }
//  override func viewWillAppear(_ animated: Bool) {
//    super.viewWillAppear(animated)
//    ViewControllerEvents.viewWillAppear.send(self)
//  }
//  override func viewDidAppear(_ animated: Bool) {
//    super.viewDidAppear(animated)
//    ViewControllerEvents.viewDidAppear.send(self)
//  }
//  override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    ViewControllerEvents.viewWillDisappear.send(self)
//  }
//  override func viewDidDisappear(_ animated: Bool) {
//    super.viewDidDisappear(animated)
//    ViewControllerEvents.viewDidDisappear.send(self)
//    if navigationController == nil && presentingViewController == nil {
//      DispatchQueue.main.async {
//        ViewControllerEvents.closed.send(self)
//      }
//    }
//  }
}
// MARK:- PScrollView
open class PScrollView: UIScrollView, AnyPScrollView {
  public var viewData = ViewData()
  open override func layoutSubviews() {
    super.layoutSubviews()
    viewData.layoutSubviews(self)
  }
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    viewData.window = self.window
  }
  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    viewData.set(traitCollection: traitCollection)
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


class ControlPipe<T: UIControl>: P<T> {
  init(_ view: T, event: UIControl.Event) {
    super.init()
    view.addTarget(self, action: #selector(receive), for: event)
  }
  @objc func receive(_ event: Any) {
    if let event = event as? T {
      send(event)
    }
  }
}
class NotificationPipe: P<Notification> {
  var subscription: Any?
  init(_ name: NSNotification.Name) {
    super.init()
    subscription = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] in
      self?.send($0)
    }
  }
}
class SelectorPipe<T>: P<T> {
  var selector: Selector { #selector(receive) }
  @objc func receive(_ event: Any) {
    if let event = event as? T {
      send(event)
    }
  }
}
public extension ObjectEvent where T: UIGestureRecognizer {
  func onAny() -> P<T> {
    let pipe = SelectorPipe<T>()
    parent.addTarget(pipe, action: pipe.selector)
    return pipe
  }
  func on(_ state: UIGestureRecognizer.State) -> P<T> {
    onAny().filter { $0.state == state }
  }
}
public extension ObjectEvent where T: UIView {
  func pan(_ setup: (UIPanGestureRecognizer)->() = { _ in }) -> P<UIPanGestureRecognizer> {
    let pipe = SelectorPipe<UIPanGestureRecognizer>()
    let gesture = UIPanGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    return pipe
  }
  func tap(_ state: UIGestureRecognizer.State? = .ended, _ setup: (UITapGestureRecognizer)->() = { _ in }) -> P<UITapGestureRecognizer> {
    let pipe = SelectorPipe<UITapGestureRecognizer>()
    let gesture = UITapGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    if let state = state {
      return pipe.filter(where: { $0.state == state })
    } else {
      return pipe
    }
  }
  func hold(_ setup: (UILongPressGestureRecognizer)->() = { _ in }) -> P<UILongPressGestureRecognizer> {
    let pipe = SelectorPipe<UILongPressGestureRecognizer>()
    let gesture = UILongPressGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    return pipe
  }
  func holdAndTap(_ setup: (UILongPressGestureRecognizer)->() = { _ in }) -> P<UIGestureRecognizer> {
    let pipe = SelectorPipe<UIGestureRecognizer>()
    let gesture = UILongPressGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    let tap = UITapGestureRecognizer(target: pipe, action: pipe.selector)
    parent.addGestureRecognizer(tap)
    return pipe
  }
  @available(iOS 13.0, *)
  func hover(_ setup: (UIHoverGestureRecognizer)->() = { _ in }) -> P<UIHoverGestureRecognizer> {
    let pipe = SelectorPipe<UIHoverGestureRecognizer>()
    let gesture = UIHoverGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    return pipe
  }
  func swipe(_ state: UIGestureRecognizer.State? = .ended, _ setup: (UISwipeGestureRecognizer)->() = { _ in }) -> P<UISwipeGestureRecognizer> {
    let pipe = SelectorPipe<UISwipeGestureRecognizer>()
    let gesture = UISwipeGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    if let state = state {
      return pipe.filter(where: { $0.state == state })
    } else {
      return pipe
    }
  }
  func screen(_ state: UIGestureRecognizer.State? = .ended, _ setup: (UIScreenEdgePanGestureRecognizer)->()) -> P<UIScreenEdgePanGestureRecognizer> {
    let pipe = SelectorPipe<UIScreenEdgePanGestureRecognizer>()
    let gesture = UIScreenEdgePanGestureRecognizer(target: pipe, action: pipe.selector)
    setup(gesture)
    parent.addGestureRecognizer(gesture)
    if let state = state {
      return pipe.filter(where: { $0.state == state })
    } else {
      return pipe
    }
  }
}

public extension ObjectEvent where T: UIControl {
  func on(_ events: UIControl.Event...) -> P<T> {
    let event = events.reduce(UIControl.Event(rawValue: 0), { $0.union($1) })
    return ControlPipe(parent, event: event)
  }
}
public extension ObjectEvent where T: UITextField {
  var text: P<String> {
    ControlPipe(parent, event: [.valueChanged, .allEditingEvents])
      .map { $0.text ?? "" }
  }
  var focus: P<Bool> {
    ControlPipe(parent, event: [.editingDidBegin, .editingDidEnd])
      .map { $0.isFirstResponder }
  }
}
public extension ObjectEvent where T: UITextView {
  var text: P<String> {
    let id = ObjectIdentifier(parent)
    let pipe = Var<String>(parent.text)
    NotificationPipe(UITextView.textDidChangeNotification)
      .compactMap { notification -> String? in
      guard let view = notification.object as? UITextView else { return nil }
      guard ObjectIdentifier(view) == id else { return nil }
      return view.text
    }.add(pipe)
    return pipe
  }
}
public extension ObjectEvent where T: UISwitch {
  var isOn: P<Bool> {
    on(.valueChanged).map(\.isOn)
  }
}
public extension ObjectEvent where T: UIDatePicker {
  var date: P<Date> {
    on(.valueChanged).map(\.date)
  }
}


// MARK:- PScrollView extensions
extension PScrollView {
  public class Delegate: NSObject, UIScrollViewDelegate {
    @Lazy public var didScroll = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var didZoom = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var willBeginDragging = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var willEndDragging = PassthroughSubject<(scrollView: UIScrollView, velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>), Never>()
    @Lazy public var didEndDragging = PassthroughSubject<(scrollView: UIScrollView, decelerate: Bool), Never>()
    @Lazy public var willBeginDecelerating = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var didEndDecelerating = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var didEndScrollingAnimation = PassthroughSubject<UIScrollView, Never>()
    public var shouldScrollToTop: ((UIScrollView) -> Bool)?
    @Lazy public var didScrollToTop = PassthroughSubject<UIScrollView, Never>()
    @Lazy public var didChangeAdjustedContentInset = PassthroughSubject<UIScrollView, Never>()
    public var zooming: ((UIScrollView)->UIView?)?
    public var didEndDraggingOrDecelerating: AnyPublisher<UIScrollView, Never> {
      didEndDragging.compactMap { $1 ? nil : $0 }.merge(with: didEndDecelerating).eraseToAnyPublisher()
    }
    
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
