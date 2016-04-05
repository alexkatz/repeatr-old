//
//  TrackAccessView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/5/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class TrackAccessView: ControlLabelView {
  
  weak var delegate: TrackSelectorDelegate?
  
  override func setup() {
    self.enabled = true
    self.label.text = "TRACKS"
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let delegate = self.delegate {
      delegate.isSelectingTrack = !delegate.isSelectingTrack
    }
  }
  
}