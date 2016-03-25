//
//  RecordView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class RecordView: UIView, RecordDelegate {

  // MARK: Overrides
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    AudioService.sharedInstance.record()
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    AudioService.sharedInstance.stop()
  }
  
  // MARK: Methods
  
  func didBeginRecording() {
    self.backgroundColor = Constants.redColor.colorWithAlphaComponent(0.8)
  }
  
  func didEndRecording() {
    self.backgroundColor = Constants.redColor
  }
  
}
