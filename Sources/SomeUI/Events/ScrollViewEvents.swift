#if canImport(UIKit)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 27/10/2020.
//

import UIKit

public protocol AnyPScrollView: UIScrollView, ViewDataProtocol {
  var pipe: PScrollView.Delegate { get }
}

public extension ObjectEvent where T: AnyPScrollView {
  var pageChanged: ScrollObjectEvent.PageChanged { .init(parent) }
  var pageSwiped: ScrollObjectEvent.PageSwiped { .init(parent) }
  var pageSwipeCompleted: ScrollObjectEvent.PageSwipeCompleted { .init(parent) }
  func loop(_ type: ScrollObjectEvent.Loop.LoopType) -> ScrollObjectEvent.Loop {
    ScrollObjectEvent.Loop(parent, type: type)
  }
  func swipedToBounds(_ bounds: Bounds) -> ScrollObjectEvent.SwipedToBounds {
    .init(parent, bounds)
  }
}

public protocol ScrollObjectEventTrigger {
  func `do`(_ action: @escaping ()->())
}
public protocol ScrollObjectEventV: ScrollObjectEventTrigger {
  associatedtype T
  func `do`(_ action: @escaping (T)->())
}
public extension ScrollObjectEventV {
  func `do`(_ action: @escaping ()->()) {
    self.do { _ in action() }
  }
}
public protocol ScrollObjectEventV2: ScrollObjectEventTrigger {
  associatedtype A
  associatedtype B
  func `do`(_ action: @escaping (A, B)->())
}
public extension ScrollObjectEventV2 {
  func `do`(_ action: @escaping ()->()) {
    self.do { _, _ in action() }
  }
}

public class ScrollObjectEvent {
  public struct Loop: ScrollObjectEventV {
    public enum LoopType {
      case duplicatedList
      /// Fullscreen elements with additional first element on the end
      case fullscreen
    }
    public enum Position {
      case start, end
    }
    unowned var scrollView: AnyPScrollView
    let type: LoopType
    init(_ scrollView: AnyPScrollView, type: LoopType) {
      self.scrollView = scrollView
      self.type = type
    }
    
    public func `do`(_ action: @escaping (Position)->()) {
      switch type {
      case .duplicatedList:
        scrollView.pipe.didScroll.forEach { scrollView in
          if scrollView.isHorizontal {
            if scrollView.contentOffset.x < 0 {
              scrollView.contentOffset.x = scrollView.contentSize.width / 2
              action(.end)
            } else if scrollView.contentOffset.x > scrollView.contentSize.width / 2 {
              scrollView.contentOffset.x = 0
              action(.start)
            }
          } else {
            if scrollView.contentOffset.y < 0 {
              scrollView.contentOffset.y = scrollView.contentSize.height / 2
              action(.end)
            } else if scrollView.contentOffset.y > scrollView.contentSize.height / 2 {
              scrollView.contentOffset.y = 0
              action(.start)
            }
          }
        }.store(in: scrollView)
      case .fullscreen:
        scrollView.pipe.didScroll.forEach { scrollView in
          if scrollView.isHorizontal {
            let offset = scrollView.contentOffset.x
            let size = scrollView.contentSize.width
            let frameSize = scrollView.frame.size.width
            let lastBound = size - frameSize
            if offset < 0 {
              scrollView.contentOffset.x = lastBound + offset
              action(.end)
            } else if offset > lastBound {
              scrollView.contentOffset.x = offset - lastBound
              action(.start)
            }
          } else {
            let offset = scrollView.contentOffset.y
            let size = scrollView.contentSize.height
            let frameSize = scrollView.frame.size.height
            let lastBound = size - frameSize
            if offset < 0 {
              scrollView.contentOffset.y = lastBound + offset
              action(.end)
            } else if offset > lastBound {
              scrollView.contentOffset.y = offset - lastBound
              action(.start)
            }
          }
        }.store(in: scrollView)
      }
    }
  }
  public struct PageChanged: ScrollObjectEventV {
    unowned var scrollView: AnyPScrollView
    init(_ scrollView: AnyPScrollView) {
      self.scrollView = scrollView
    }
    public func `do`(_ action: @escaping (Int)->()) {
      var page = 0
      scrollView.pipe.didScroll.forEach { scrollView in
        let p = scrollView.page
        if page != p {
          page = p
          action(page)
        }
      }.store(in: scrollView)
    }
  }
  public struct PageSwiped: ScrollObjectEventV {
    unowned var scrollView: AnyPScrollView
    init(_ scrollView: AnyPScrollView) {
      self.scrollView = scrollView
    }
    
    public func `do`(_ action: @escaping (Int)->()) {
      var page = 0
      scrollView.pipe.willBeginDragging.sink { scrollView in
        page = scrollView.page
      }.store(in: scrollView)
      scrollView.pipe.willEndDragging.sink { scrollView, velocity, deceleration in
        let p = Int(scrollView.pageProgress(for: deceleration.pointee)
                      .rounded(.toNearestOrAwayFromZero))
        if page != p {
          page = p
          action(page)
        }
      }.store(in: scrollView)
    }
  }
  public struct PageSwipeCompleted: ScrollObjectEventV {
    unowned var scrollView: AnyPScrollView
    init(_ scrollView: AnyPScrollView) {
      self.scrollView = scrollView
    }
    
    public func `do`(_ action: @escaping (Int)->()) {
      var page = 0
      var locked = false
      scrollView.pipe.willBeginDragging.sink { scrollView in
        if !locked {
          page = scrollView.page
        }
      }.store(in: scrollView)
      scrollView.pipe.didEndDecelerating.sink { scrollView in
        let p = Int(scrollView.pageProgress.rounded(.toNearestOrAwayFromZero))
        if page != p {
          page = p
          action(page)
        }
        locked = false
      }.store(in: scrollView)
      
      scrollView.pipe.didEndDragging.sink { scrollView, decelerate in
        if decelerate {
          locked = true
        } else {
          let p = Int(scrollView.pageProgress.rounded(.toNearestOrAwayFromZero))
          if page != p {
            page = p
            action(page)
          }
          locked = false
        }
      }.store(in: scrollView)
    }
  }
  public struct SwipedToBounds: ScrollObjectEventV {
    unowned var scrollView: AnyPScrollView
    var bounds: Bounds
    init(_ scrollView: AnyPScrollView, _ bounds: Bounds) {
      self.scrollView = scrollView
      self.bounds = bounds
    }
    public func `do`(_ action: @escaping (Bound)->()) {
      let bounds = self.bounds
      guard bounds != 0 else { return }
      scrollView.pipe.willEndDragging.sink { scrollView, velocity, deceleration in
        if let bound = scrollView.boundHit, bounds.contains(bound) {
          action(bound)
        }
      }.store(in: scrollView)
    }
  }
}

#endif
