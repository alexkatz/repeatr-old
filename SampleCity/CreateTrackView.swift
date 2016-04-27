//
//  NewTrackView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/25/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class CreateTrackView: ControlLabelView {
  
  var parent: HomeViewController?
  
  override func setup() {
    self.label.numberOfLines = 2
    self.label.text = "CREATE\nTRACK"
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.parent?.createTrack()
  }
  
}
