//
//  WaveformGestureRecognizer.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/29/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class WaveformGestureRecognizer: UIGestureRecognizer {
  
  fileprivate weak var waveformView: WaveformView?
  
  init(waveformView: WaveformView) {
    self.waveformView = waveformView
    super.init(target: nil, action: nil)
    self.delaysTouchesEnded = false
    self.delaysTouchesBegan = false
  }
  
  override func reset() {
    super.reset()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    self.waveformView?.touchesBegan(touches)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    self.waveformView?.touchesMoved(touches)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    self.waveformView?.touchesEnded(touches)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
  }
  
  override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
  
}
