#if os(iOS)
//
//  UISegmentedControl.swift
//  Some
//
//  Created by Димасик on 02/09/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import UIKit

extension UISegmentedControl {
  public func removeBorders() {
    setBackgroundImage(imageWithColor(backgroundColor!), for: UIControl.State(), barMetrics: .default)
    setBackgroundImage(imageWithColor(tintColor!), for: .selected, barMetrics: .default)
    setDividerImage(imageWithColor(.clear), forLeftSegmentState: UIControl.State(), rightSegmentState: UIControl.State(), barMetrics: .default)
  }
  
  // create a 1x1 image with this color
  private func imageWithColor(_ color: UIColor) -> UIImage {
    let rect = CGRect(0,0,1,1)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color.cgColor);
    context?.fill(rect);
    let image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image!
  }
}
#endif
