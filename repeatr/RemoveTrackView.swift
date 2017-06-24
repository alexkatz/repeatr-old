//
//  RemoveTrackView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/28/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class RemoveTrackView : ControlLabelView {
  
  fileprivate var touch: UITouch?
  
  override func setup() {
    self.label.text = "REMOVE"
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.touch = touches.first
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if self.touch == touches.first, let touch = self.touch , self.bounds.contains(touch.location(in: self)) {
      if let trackService = self.trackService {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationDestroyTrack), object: self, userInfo: [Constants.trackServiceUUIDKey: trackService.uuid])
      }
    }
  }
}
