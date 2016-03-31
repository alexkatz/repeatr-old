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

  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var waveformView: WaveformView!
  @IBOutlet weak var loopRecordView: LoopRecordView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.blackColor()
    self.recordView.backgroundColor = Constants.redColor
    self.waveformView.backgroundColor = Constants.greenColor
    
    AudioService.sharedInstance.recordDelegate = self.recordView
    AudioService.sharedInstance.playbackDelegate = self.waveformView
    AudioService.sharedInstance.meterDelegate = self.waveformView
    AudioService.sharedInstance.loopRecordDelegate = self.loopRecordView
  }

  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
}

