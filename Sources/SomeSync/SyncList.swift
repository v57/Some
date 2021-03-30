//
//  File.swift
//  
//
//  Created by Дмитрий Козлов on 15.02.2021.
//

import Some
import Combine

/// Elements in this collection will never change
protocol StaticList {
  associatedtype Index: Comparable
  associatedtype Element
  func select<R: RangeExpression>(_ range: R) -> ArraySlice<Element>
}

/// Elements can be appended here
protocol AddictiveList {
  associatedtype Index: Comparable
  associatedtype Element
  func append<C: Collection>(_ collection: C) where C.Element == Element
}

/// Elements can be appended here
protocol InsertableList {
  
}
