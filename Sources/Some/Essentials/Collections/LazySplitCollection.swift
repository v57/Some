//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/10/20.
//

import Foundation

public struct LazySplitCollection<Base: Collection>: Collection where Base.Element: Equatable {
  public struct Index: Comparable {
    public let start, end: Base.Index
    public static func ==(lhs: Index, rhs: Index) -> Bool { lhs.start == rhs.start }
    public static func < (lhs: Index, rhs: Index) -> Bool { lhs.start < rhs.start }
  }

  let _base: Base
  let _separator: Base.Element

  public var startIndex: Index { Index(start: _base.startIndex, end: findEnd(_base.startIndex)) }
  public var endIndex: Index { Index(start: _base.endIndex, end: _base.endIndex) }

  public func index(after i : Index) -> Index {
    if i.end == _base.endIndex {
      return endIndex
    } else {
      let nextStart = _base.index(after: i.end)
      let nextEnd = findEnd(nextStart)
      return Index(start: nextStart, end: nextEnd)
    }
  }

  public subscript(i: Index) -> Base.SubSequence { _base[i.start..<i.end] }

  public func findEnd(_ i: Base.Index) -> Base.Index {
    _base[i...].firstIndex(of: _separator) ?? _base.endIndex
  }
}

public extension LazyCollectionProtocol where Elements.Element: Equatable {
  func split(separator: Elements.Element) -> LazySplitCollection<Elements> {
    return LazySplitCollection(_base: self.elements, _separator: separator)
  }
}
