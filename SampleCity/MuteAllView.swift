//
//  MuteAllView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/23/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class MuteAllView: ControlLabelView {

  private let loopService = LoopService.sharedInstance
  private let muteAllText = "MUTE"
  private let unmuteAllText = "UNMUTE"
  
  override func setup() {
    self.enabled = true
    self.label.text = self.muteAllText
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.loopService.muteAll = !self.loopService.muteAll
    self.label.text = self.loopService.muteAll ? self.unmuteAllText : self.muteAllText
  }
  
}
