//
//  ViewController.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/19/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
  
  var audioPlayer: AVAudioPlayer!
  var audioRecorder: AVAudioRecorder!
  
  @IBOutlet weak var recordView: UIView!
  @IBOutlet weak var playView: WaveformView!
  
  let defaultAlpha = CGFloat(0.4)
  let pressedAlpha = CGFloat(1)
  
  // MARK: Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.recordView.alpha = self.defaultAlpha
    self.playView.alpha = self.defaultAlpha
    
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
    let documentsDirectory = paths[0]
    
    let audioFilePath = (documentsDirectory as NSString).stringByAppendingPathComponent("audio.m4a")
    let audioFileURL = NSURL(fileURLWithPath: audioFilePath)
    let recordSettings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1 as NSNumber,
      AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
    ]
    
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
      try AVAudioSession.sharedInstance().setActive(true)
      self.audioRecorder = try AVAudioRecorder(URL: audioFileURL, settings: recordSettings)
      self.audioRecorder.delegate = self
      self.audioRecorder.prepareToRecord()
    } catch {
      print("There was a problem setting play and record audio session category.")
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let location = touches.first?.locationInView(self.view) {
      if self.recordView.frame.contains(location) {
        self.recordView.alpha = self.pressedAlpha
        self.recordAudio()
      } else {
        self.playView.alpha = self.pressedAlpha
        self.playAudio()
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.stopAudio()
    self.recordView.alpha = self.defaultAlpha
    self.playView.alpha = self.defaultAlpha
  }
  
  // MARK: Methods
  
  func recordAudio() {
    if !self.audioRecorder.recording {
      self.audioRecorder.record()
    }
  }
  
  func stopAudio() {
    if self.audioRecorder.recording {
      self.audioRecorder.stop()
    } else if self.audioPlayer != nil && self.audioPlayer.playing {
      self.audioPlayer.stop()
    }
  }
  
  func playAudio() {
    do {
      try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioRecorder.url)
      self.audioPlayer.delegate = self
      self.audioPlayer.play()
    } catch {
      print("Error playing audio.")
    }
    
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playView.audioURL = recorder.url
    }
  }
  
}

