//
//  UIColorExtensions.swift
//  Repeatr
//
//  Created by Alexander Katz on 10/22/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

extension UIColor {
  
  class func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat? = nil) -> UIColor {
    return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha ?? 1)
  }
  
  @nonobjc static let funMagenta = UIColor.rgb(red: 244, green: 154, blue: 194)
  @nonobjc static let funViolet = UIColor.rgb(red: 203, green: 153, blue: 201)
  @nonobjc static let funPink = UIColor.rgb(red: 255, green: 209, blue: 220)
  @nonobjc static let funGreen = UIColor.rgb(red: 119, green: 190, blue: 119)
  @nonobjc static let funOrange = UIColor.rgb(red: 255, green: 179, blue: 71)
  @nonobjc static let funLightPurple = UIColor.rgb(red: 100, green: 20, blue: 100)
  @nonobjc static let funDarkPurple = UIColor.rgb(red: 150, green: 11, blue: 214)
  @nonobjc static let funYellow = UIColor.rgb(red: 253, green: 253, blue: 150)
  
  @nonobjc static let funColors = [
    UIColor.funMagenta,
    UIColor.funViolet,
    UIColor.funPink,
    UIColor.funGreen,
    UIColor.funOrange,
    UIColor.funLightPurple,
    UIColor.funDarkPurple,
  ]
  
  class func randomFunColor() -> UIColor {
    return UIColor.funColors[Int(arc4random_uniform(UInt32(UIColor.funColors.count)))]
  }
  
}
