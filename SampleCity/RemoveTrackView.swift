//
//  RemoveTrackView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/28/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class RemoveTrackView : ControlLabelView {
  
  private var touch: UITouch?
  
  override func setup() {
    self.label.text = "REMOVE"
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.touch = touches.first
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.touch == touches.first, let touch = self.touch where self.bounds.contains(touch.locationInView(self)) {
      if let trackService = self.trackService {
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.notificationDestroyTrack, object: self, userInfo: [Constants.trackServiceUUIDKey: trackService.uuid])
      }
    }
  }
}