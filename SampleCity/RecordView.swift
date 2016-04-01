//
//  RecordView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class RecordView: UIView, RecordDelegate {
  
  private let audioService = AudioService.sharedInstance
  
  var isRecording: Bool = false {
    didSet {
      self.backgroundColor = Constants.redColor.colorWithAlphaComponent(self.isRecording ? 0.8 : 1)
    }
  }
  
  var isLoopRecording: Bool = false {
    didSet {
      
    }
  }
  
  // MARK: Overrides
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.audioService.recordAudio()
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.audioService.stopAudio()
  }
  
}
