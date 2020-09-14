//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/10/20.
//

import Foundation

public struct LazySplitCollection<Base: Collection>: Collection
    where Base.Element: Equatable
{
    public struct Index: Comparable {
        public let start, end: Base.Index
        public static func ==(lhs: Index, rhs: Index) -> Bool { return lhs.start == rhs.start }
        public static func < (lhs: Index, rhs: Index) -> Bool { return lhs.start < rhs.start }
    }
    
    public func findEnd(_ i: Base.Index) -> Base.Index {
      return _base[i...].firstIndex(of: _separator) ?? _base.endIndex
    }
    
    let _base: Base
    let _separator: Base.Element
    
    public var startIndex: Index { return Index(start: _base.startIndex, end: findEnd(_base.startIndex)) }
    public var endIndex: Index { return Index(start: _base.endIndex, end: _base.endIndex) }
    
    public func index(after i : Index) -> Index {
        if i.end == _base.endIndex {
            return endIndex
        }
        else {
            let nextStart = _base.index(after: i.end)
            let nextEnd = findEnd(nextStart)
            return Index(start: nextStart, end: nextEnd)
        }
    }
    
    public subscript(i: Index) -> Base.SubSequence {
        return _base[i.start..<i.end]
    }
}

public extension LazyCollectionProtocol
where Elements.Element: Equatable,
      Elements.SubSequence: Collection
{
    func split(separator: Elements.Element) -> LazySplitCollection<Elements> {
        return LazySplitCollection(_base: self.elements, _separator: separator)
    }
}
