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
    self.label.text = "MIX"
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.delegate?.toggleTrackEditMode()
  }
  
}
