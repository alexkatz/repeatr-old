//
//  VolumeControlView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/15/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class VolumeControlView: UIView {
  
  private var activeTouch: UITouch?
  private var filledView = UIView()
  
  weak var delegate: AudioVolumeDelegate?
  
  var volumeLevel: Float = 1 {
    didSet {
      self.delegate?.volumeLevel = self.volumeLevel
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    self.filledView.backgroundColor = Constants.whiteColor
    
  }
  
}