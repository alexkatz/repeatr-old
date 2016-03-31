//
//  ViewController.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/19/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController {

  private let audioService = AudioService.sharedInstance
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var waveformView: WaveformView!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var loopPlaybackView: LoopPlaybackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.blackColor()
    self.recordView.backgroundColor = Constants.redColor
    self.waveformView.backgroundColor = Constants.greenColor
    
    self.audioService.recordDelegate = self.recordView
    self.audioService.playbackDelegate = self.waveformView
    self.audioService.meterDelegate = self.waveformView
    self.audioService.loopRecordDelegate = self.loopRecordView
    self.audioService.loopPlaybackDelegate = self.loopPlaybackView
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
}

