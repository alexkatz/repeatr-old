//
//  BottomLabelView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/5/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import UIKit

class ControlLabelView: UIView, Disablable {
  
  var trackService: TrackService?
  
  var enabled = false {
    didSet {
      self.alpha = self.enabled ? 1 : Constants.dimAlpha
      self.userInteractionEnabled = self.enabled
    }
  }
  
  lazy var label: UILabel = { [unowned self] in
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Constants.font
    label.textColor = UIColor.whiteColor()
    label.textAlignment = .Center
    self.addSubview(label)
    label.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    label.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
    return label
    }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  func setup() {
    
  }
  
}