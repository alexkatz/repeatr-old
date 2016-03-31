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
  
  private struct LoopPoint {
    let intervalFromStart: UInt64
    let audioTime: Double?
  }
  
  private let playbackQueue = NSOperationQueue()
  
  private var audioPlayer: AVAudioPlayer?
  private var audioRecorder: AVAudioRecorder!
  private var cursorTimer: NSTimer?
  private var meterTimer: NSTimer?
  private var loopPoints = [LoopPoint]()
  private var loopStartTime: UInt64!
  
  static let sharedInstance = AudioService()
  
  var isArmedForLoopRecord = false {
    didSet {
      self.loopRecordDelegate?.isArmed = self.isArmedForLoopRecord
    }
  }
  
  var isLoopRecording = false {
    didSet {
      self.loopRecordDelegate?.isLoopRecording = self.isLoopRecording
      if self.isLoopRecording {
        self.startLoopRecord()
      } else {
        self.stopLoopRecord()
      }
    }
  }
  
  var isPlayingLoop = false {
    didSet {
      self.loopPlaybackDelegate?.isPlayingLoop = self.isPlayingLoop
      if self.isPlayingLoop {
      } else {
        self.audioPlayer?.pause()
      }
    }
  }
  
  var pauseCondition = NSCondition()
  
  weak var recordDelegate: RecordDelegate?
  weak var playbackDelegate: PlaybackDelegate?
  weak var loopRecordDelegate: LoopRecordDelegate?
  weak var loopPlaybackDelegate: LoopPlaybackDelegate?
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
    
    self.playbackQueue.maxConcurrentOperationCount = 1
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
      try audioSession.setPreferredIOBufferDuration(0.001)
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
      self.recordDelegate?.isRecording = true
      if self.meterTimer == nil {
        self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: #selector(AudioService.updateMeters), userInfo: nil, repeats: true)
      }
    }
  }
  
  func play(startPercent percent: Double = 0) {
    if let audioPlayer = self.audioPlayer {
      let audioTime = audioPlayer.duration * percent
      
      if self.isArmedForLoopRecord && !self.isLoopRecording { // first sample marks downbeat of 1 in loop in this case
        self.isLoopRecording = true
      }
      
      if let loopStartTime = self.loopStartTime where self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - loopStartTime,
          audioTime: audioTime))
      }
      
      audioPlayer.currentTime = audioTime
      audioPlayer.play()
      self.startCursorTimer()
    }
  }
  
  func stop() {
    if self.audioRecorder.recording {
      self.audioRecorder.stop()
      self.recordDelegate?.isRecording = false
      self.meterTimer?.invalidate()
      self.meterTimer = nil
      self.meterDelegate?.dbLevel = nil
    } else if self.audioPlayer != nil {
      if let loopStartTime = self.loopStartTime where self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - loopStartTime,
          audioTime: nil))
      }
      
      self.audioPlayer?.pause()
      self.cursorTimer?.invalidate()
      self.cursorTimer = nil
      self.playbackDelegate?.currentTime = nil
    }
  }
  
  func startLoopRecord() {
    self.loopStartTime = mach_absolute_time()
  }
  
  func stopLoopRecord() {
    if let loopStartTime = self.loopStartTime {
      self.loopPoints.append(LoopPoint(
        intervalFromStart: mach_absolute_time() - loopStartTime,
        audioTime: nil))
    }
    
    self.startLoop()
  }
  
  func startLoop() {
    self.isPlayingLoop = true
    self.startCursorTimer()
    self.playbackQueue.addOperationWithBlock {
      var i = 0
      var startTime = mach_absolute_time()
      repeat {
        if i < self.loopPoints.count {
          let loopPoint = self.loopPoints[i]
          let intervalFromStart = mach_absolute_time() - startTime
          if  intervalFromStart >= loopPoint.intervalFromStart {
            if let audioTime = loopPoint.audioTime {
              self.audioPlayer?.currentTime = audioTime
              self.audioPlayer?.play()
            } else {
              self.audioPlayer?.pause()
            }
            i += 1
          }
        } else {
          i = 0
          startTime = mach_absolute_time()
        }
      } while (self.isPlayingLoop)
    }
  }
  
  func pauseLoop() {
    self.isPlayingLoop = false
  }
  
  func updateCurrentTime() {
    if let audioPlayer = self.audioPlayer {
      self.playbackDelegate?.currentTime = audioPlayer.currentTime
    }
  }
  
  func updateMeters() {
    self.audioRecorder.updateMeters()
    self.meterDelegate?.dbLevel = self.audioRecorder.averagePowerForChannel(0)
  }
  
  private func startCursorTimer() {
    if self.cursorTimer == nil {
      let interval = 0.001
      self.cursorTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(AudioService.updateCurrentTime), userInfo: nil, repeats: true)
      self.cursorTimer?.tolerance = interval * 0.10
    }
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playbackDelegate?.audioURL = recorder.url
      do {
        try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioRecorder.url)
        self.audioPlayer?.prepareToPlay()
      } catch let error as NSError {
        print("Error setting audio player URL: \(error.localizedDescription)")
      }
    }
  }
  
}