//
//  AudioService.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import AVFoundation

class TrackService: NSObject, AVAudioRecorderDelegate {
  
  private let playbackQueue = NSOperationQueue()
  private let loopService = LoopService.sharedInstance
  
  private var audioPlayer: AVAudioPlayer?
  private var audioRecorder: AVAudioRecorder!
  private var cursorTimer: NSTimer?
  private var meterTimer: NSTimer?
  private var loopPoints = [LoopPoint]()
  private var loopStartTime: UInt64?
  
  let uuid = NSUUID().UUIDString
  
  var isArmedForLoopRecord = false {
    didSet {
      self.loopRecordDelegate?.isArmed = self.isArmedForLoopRecord
    }
  }
  
  var isLoopRecording = false {
    didSet {
      self.loopRecordDelegate?.isLoopRecording = self.isLoopRecording
      self.trackAccessDelegate?.enabled = !self.isLoopRecording
    }
  }
  
  var isPlayingLoop = false {
    didSet {
      self.loopPlaybackDelegate?.isPlayingLoop = self.isPlayingLoop
      self.recordDelegate?.enabled = !self.isPlayingLoop
    }
  }
  
  var loopExists = false {
    didSet {
      self.loopPlaybackDelegate?.loopExists = self.loopExists
    }
  }
  
  var audioFileURL: NSURL {
    get {
      let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
      let documentsDirectory = paths[0]
      let audioFilePath = (documentsDirectory as NSString).stringByAppendingPathComponent("\(self.uuid).caf")
      return NSURL(fileURLWithPath: audioFilePath)
    }
  }
  
  var volumeLevel: Float {
    get {
      return self.audioPlayer != nil ? self.audioPlayer!.volume : 0
    }
    set {
      self.audioPlayer?.volume = newValue
    }
  }
  
  weak var recordDelegate: RecordDelegate?
  weak var playbackDelegate: PlaybackDelegate?
  weak var loopRecordDelegate: LoopRecordDelegate?
  weak var loopPlaybackDelegate: LoopPlaybackDelegate? {
    didSet {
      self.loopPlaybackDelegate?.isPlayingLoop = self.isPlayingLoop
      self.loopPlaybackDelegate?.enabled = self.loopExists
    }
  }
  weak var meterDelegate: MeterDelegate?
  weak var trackAccessDelegate: ControlLabelView?
  
  let noiseFloor = Float(-50.0)
  
  override init() {
    super.init()
    
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
      self.audioRecorder = try AVAudioRecorder(URL: self.audioFileURL, settings: recordSettings)
      self.audioRecorder.delegate = self
      self.audioRecorder.prepareToRecord()
      self.audioRecorder.meteringEnabled = true
    } catch let error as NSError {
      print("There was a problem setting play and record audio session category: \(error.localizedDescription)")
    }
  }
  
  func recordAudio() {
    if !self.audioRecorder.recording {
      self.clearLoop()
      self.audioRecorder.record()
      self.playbackDelegate?.audioURL = nil
      self.recordDelegate?.isRecording = true
      self.loopRecordDelegate?.enabled = false
      self.trackAccessDelegate?.enabled = false
      if self.meterTimer == nil {
        self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: #selector(TrackService.updateMeters), userInfo: nil, repeats: true)
      }
      self.loopPlaybackDelegate?.loopExists = false
    }
  }
  
  func playAudioWithStartPercent(percent: Double) {
    if let audioPlayer = self.audioPlayer {
      let audioTime = audioPlayer.duration * percent
      
      if self.isArmedForLoopRecord && !self.isLoopRecording { // first sample marks downbeat of 1 in loop in this case
        self.startLoopRecord()
      }
      
      if self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - self.getLoopStartTime(),
          audioTime: audioTime,
          audioPlayer: audioPlayer))
      }
      
      audioPlayer.currentTime = audioTime
      audioPlayer.play()
      self.startCursorTimer()
    }
  }
  
  func stopAudio() {
    if self.audioRecorder.recording {
      self.audioRecorder.stop()
      self.recordDelegate?.isRecording = false
      self.meterTimer?.invalidate()
      self.meterTimer = nil
      self.meterDelegate?.dbLevel = nil
      self.trackAccessDelegate?.enabled = true
    } else if let audioPlayer = self.audioPlayer where audioPlayer.playing {
      if self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - self.getLoopStartTime(),
          audioTime: nil,
          audioPlayer: audioPlayer))
      }
      
      self.audioPlayer?.pause()
      self.cursorTimer?.invalidate()
      self.cursorTimer = nil
      self.playbackDelegate?.currentTime = nil
    }
  }
  
  func startLoopRecord() {
    self.clearLoop()
    self.isArmedForLoopRecord = false
    self.isLoopRecording = true
    
    if self.loopService.currentLoopStartTime == nil {
      self.loopStartTime = mach_absolute_time()
    }
  }
  
  func finishLoopRecord() {
    if let audioPlayer = self.audioPlayer {
      self.loopPoints.append(LoopPoint(
        intervalFromStart: mach_absolute_time() - self.getLoopStartTime(),
        audioTime: nil,
        audioPlayer: audioPlayer))
    }
    self.isLoopRecording = false
    self.loopExists = true
    self.addToLoopPlayback()
  }
  
  func addToLoopPlayback() {
    self.isPlayingLoop = true
    self.startCursorTimer()
    
    if !self.loopService.hasLoopPoints {
      self.loopService.masterTrackService = self
    }
    
    self.loopService.addLoopPoints(self.loopPoints)
    
    if !self.loopService.isPlayingLoop {
      self.loopService.startLoopPlayback()
    }
  }
  
  func removeFromLoopPlayback() {
    self.isPlayingLoop = false
    self.loopService.removeLoopPoints(self.loopPoints)
    self.cursorTimer?.invalidate()
    self.cursorTimer = nil
    self.playbackDelegate?.removeCursor()
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
      self.cursorTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(TrackService.updateCurrentTime), userInfo: nil, repeats: true)
      self.cursorTimer?.tolerance = interval * 0.10
    }
  }
  
  private func clearLoop() {
    self.removeFromLoopPlayback()
    self.isLoopRecording = false
    self.loopPoints.removeAll()
  }
  
  private func getLoopStartTime() -> UInt64 {
    return self.loopStartTime ?? self.loopService.currentLoopStartTime!
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playbackDelegate?.audioURL = recorder.url
      self.loopRecordDelegate?.enabled = true
      do {
        try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioRecorder.url)
        self.audioPlayer?.prepareToPlay()
      } catch let error as NSError {
        print("Error setting audio player URL: \(error.localizedDescription)")
      }
    }
  }
  
}