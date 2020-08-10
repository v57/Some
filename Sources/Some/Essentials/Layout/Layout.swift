//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/8/20.
//

import Swift

// struct LayoutContext {
//   var minimum: CGSize
//   var maximum: CGSize
// }
// protocol LayoutItem {
//   var layoutContext: LayoutContext { get }
//   func size(context: LayoutContext) -> CGSize
//   func minSize(context: LayoutContext) -> CGSize
// }
// struct LineBuilderItem {
//   let item: LayoutItem
//   let context: LayoutContext
// }
// struct HLineBuilder {
//   var width: CGFloat
//   var gap: CGFloat
//   
//   var space: CGFloat
//   var items: [LineBuilderItem]
//   mutating func append(item: LayoutItem) -> LayoutContext? {
//     let context = item.layoutContext
//     if context.minimum.width > space {
//       return context
//     } else {
//       items.append(LineBuilderItem(item: item, context: context))
//       space -= context.minimum.width
//       space -= gap
//       return nil
//     }
//   }
// }
