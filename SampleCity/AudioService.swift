//
//  AudioService.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import AVFoundation

class AudioService: NSObject, AVAudioRecorderDelegate {
  
  private var audioPlayer: AVAudioPlayer!
  private var audioRecorder: AVAudioRecorder!
  private var playbackTimer: NSTimer?
  private var meterTimer: NSTimer?
  
  static let sharedInstance = AudioService()
  
  weak var playbackDelegate: PlaybackDelegate?
  weak var recordDelegate: RecordDelegate?
  weak var meterDelegate: MeterDelegate?
  
  let noiseFloor = Float(-50.0)
  
  override init() {
    super.init()
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
    let documentsDirectory = paths[0]
    
    let audioFilePath = (documentsDirectory as NSString).stringByAppendingPathComponent("audio.caf")
    let audioFileURL = NSURL(fileURLWithPath: audioFilePath)
    let recordSettings = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: NSNumber(float: 44100.0),
      AVNumberOfChannelsKey: NSNumber(int: 1),
      AVLinearPCMBitDepthKey: NSNumber(int: 16),
      AVLinearPCMIsBigEndianKey: NSNumber(bool: false),
      AVLinearPCMIsFloatKey: NSNumber(bool: false)
    ]
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
      try audioSession.setPreferredIOBufferDuration(0.0006)
      try AVAudioSession.sharedInstance().setActive(true)
      self.audioRecorder = try AVAudioRecorder(URL: audioFileURL, settings: recordSettings)
      self.audioRecorder.delegate = self
      self.audioRecorder.prepareToRecord()
      self.audioRecorder.meteringEnabled = true
    } catch let error as NSError {
      print("There was a problem setting play and record audio session category: \(error.localizedDescription)")
    }
  }
  
  func record() {
    if !self.audioRecorder.recording {
      self.audioRecorder.record()
      self.playbackDelegate?.audioURL = nil
      self.recordDelegate?.didBeginRecording()
      if self.meterTimer == nil {
        self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: #selector(AudioService.updateMeters), userInfo: nil, repeats: true)
      }
    }
  }
  
  func play(startPercent percent: Double = 0) {
    self.audioPlayer.currentTime = self.audioPlayer.duration * percent
    self.audioPlayer.play()
    
    if self.playbackTimer == nil {
      self.playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: #selector(AudioService.updateCurrentTime), userInfo: nil, repeats: true)
    }
  }
  
  func stop() {
    if self.audioRecorder.recording {
      self.audioRecorder.stop()
      self.recordDelegate?.didEndRecording()
      self.meterTimer?.invalidate()
      self.meterTimer = nil
      self.meterDelegate?.dbLevel = nil
    } else if self.audioPlayer != nil {
      self.audioPlayer.pause()
      self.playbackTimer?.invalidate()
      self.playbackTimer = nil
      self.playbackDelegate?.currentTime = nil
    }
  }
  
  func updateCurrentTime() {
    self.playbackDelegate?.currentTime = self.audioPlayer.currentTime
  }
  
  func updateMeters() {
    self.audioRecorder.updateMeters()
    self.meterDelegate?.dbLevel = self.audioRecorder.averagePowerForChannel(0)
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playbackDelegate?.audioURL = recorder.url
      do {
        try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioRecorder.url)
        self.audioPlayer.prepareToPlay()
      } catch let error as NSError {
        print("Error setting audio player URL: \(error.localizedDescription)")
      }
    }
  }
  
}