//
//  LoopRecordCancelView.swift
//  Repeatr
//
//  Created by Alexander Katz on 10/11/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LoopRecordCancelView: ControlLabelView {
  
  weak var parent: HomeViewController?
  
  var touch: UITouch?
  
  override func setup() {
    self.label.text = "CANCEL"
    self.backgroundColor = Constants.darkerRedColor
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.touch = touches.first
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if self.touch == touches.first, let touch = self.touch , self.bounds.contains(touch.location(in: self)) {
      self.parent?.dismissActiveLoopRecord()
      self.touch = nil
    }
  }
}
