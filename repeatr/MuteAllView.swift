//
//  MuteAllView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/23/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class MuteAllView: ControlLabelView {

  fileprivate let loopService = LoopService.sharedInstance
  fileprivate let muteAllText = "MUTE ALL"
  fileprivate let unmuteAllText = "UNMUTE ALL"
  
  override func setup() {
    self.enabled = true
    self.label.text = self.muteAllText
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.loopService.muteAll = !self.loopService.muteAll
    self.label.text = self.loopService.muteAll ? self.unmuteAllText : self.muteAllText
  }
  
}
