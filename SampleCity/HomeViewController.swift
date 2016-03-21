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
  var playbackTimer: NSTimer!
  
  @IBOutlet weak var recordView: UIView!
  @IBOutlet weak var playView: WaveformView!
  @IBOutlet weak var recordLabel: UILabel!
  
  let greenColor = UIColor(red: 0.0/255.0, green: 235.0/255.0, blue: 151.0/255.0, alpha: 1)
  let redColor = UIColor(red: 224.0/255.0, green: 115.0/255.0, blue: 133.0/255.0, alpha: 1)
  
  let notRecordingText = "Hold to record"
  let recordingText = "Recording..."
  
  // MARK: Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.blackColor()
    
    self.recordView.backgroundColor = self.redColor
    self.playView.backgroundColor = self.greenColor
    
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
        self.recordAudio()
        self.recordView.backgroundColor = self.redColor.colorWithAlphaComponent(0.8)
        self.recordLabel.text = self.recordingText
        self.view.setNeedsLayout()
      } else {
        let percent = Double(location.x / self.view.bounds.width)
        self.playAudio(startPercent: percent)
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.stopAudio()
    self.recordView.backgroundColor = self.redColor
    self.playView.backgroundColor = self.greenColor
    self.recordLabel.text = self.notRecordingText
    self.view.setNeedsLayout()
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
      self.playbackTimer.invalidate()
      self.playbackTimer = nil
      self.playView.removeCursor()
    }
  }
  
  func playAudio(startPercent percent: Double? = nil) {
    do {
      try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioRecorder.url)
      self.audioPlayer.delegate = self
      
      if let percent = percent {
        self.audioPlayer.currentTime = self.audioPlayer.duration * percent
      }
      
      self.audioPlayer.play()
      
      if self.playbackTimer == nil {
        self.playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "setPlaybackCursor", userInfo: nil, repeats: true)
      }
    } catch {
      print("Error playing audio.")
    }
  }
  
  func setPlaybackCursor() {
    let duration = self.audioPlayer.duration
    let current = self.audioPlayer.currentTime
    let percentComplete = CGFloat(current / duration)
    self.playView.setCursorPositionWithPercent(percentComplete)
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playView.audioURL = recorder.url
    }
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
}

