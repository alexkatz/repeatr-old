//
//  LayoutHelper.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/8/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LayoutHelper {
  
  class func addInfoLabel(label: UILabel, toView view: UIView) {
    view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
    label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
    label.widthAnchor.constraintLessThanOrEqualToAnchor(view.widthAnchor, constant: -32).active = true
    label.layer.shouldRasterize = true
  }
  
  class func createInfoLabel() -> UILabel {
    let label = UILabel()
    label.textColor = Constants.whiteColor
    label.font = Constants.font
    label.textAlignment = .Center
    label.numberOfLines = 2
    return label
  }
  
}