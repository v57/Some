#if os(iOS)
//
//  File.swift
//  
//
//  Created by Dmitry on 06.10.2019.
//

import UIKit

public struct EasyCellCache<T: UICollectionViewCell> {
  private let v = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
  public init() {
    v.register(T.self, forCellWithReuseIdentifier: "_")
  }
  public func get() -> T {
    return v.dequeueReusableCell(withReuseIdentifier: "_", for: IndexPath(item: 0, section: 0)) as! T
  }
  public func get(_ index: Int) -> T {
    return v.dequeueReusableCell(withReuseIdentifier: "_", for: IndexPath(item: index, section: 0)) as! T
  }
}
#endif
