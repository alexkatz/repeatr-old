//
//  LayoutHelper.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/8/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LayoutHelper {
  
  class func addInfoLabel(_ label: UILabel, toView view: UIView) {
    view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32).isActive = true
    label.layer.shouldRasterize = true
  }
  
  class func createInfoLabel() -> UILabel {
    let label = UILabel()
    label.textColor = Constants.whiteColor
    label.font = Constants.font
    label.textAlignment = .center
    label.numberOfLines = 2
    return label
  }
  
}
