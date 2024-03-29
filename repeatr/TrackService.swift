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
  
  private let playbackQueue = OperationQueue()
  private let loopService = LoopService.sharedInstance // TODO: get rid of this and just do LoopService.sharedInstance
  
  private var audioPlayer: AVAudioPlayer?
  private var audioRecorder: AVAudioRecorder!
  private var cursorTimer: Timer?
  private var meterTimer: Timer?
  private var loopPoints = [LoopPoint]()
  private var internalLoopStartTime: UInt64? // used only if nothing is already looping, otherwise current loop time is taken from loopService
  private var internalRecordStartTime: UInt64?
  private var currentVolumeLevel: Float = 0
  
  
  let uuid = UUID().uuidString
  
  var isArmedForLoopRecord = false {
    didSet {
      if self.isArmedForLoopRecord != oldValue {
        self.loopRecordDelegate?.didChangeIsArmed(self.isArmedForLoopRecord)
        if self.isArmedForLoopRecord {
          NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: Constants.notificationLoopRecordArmed), object: self))
        }
      }
    }
  }
  
  var isLoopRecording = false {
    didSet {
      if self.isLoopRecording != oldValue {
        DispatchQueue.main.async {
          self.loopRecordDelegate?.didChangeIsLoopRecording(self.isLoopRecording)
          self.trackAccessDelegate?.enabled = !self.isLoopRecording
        }
      }
    }
  }
  
  var isPlayingLoop = false {
    didSet {
      self.loopPlaybackDelegate?.isPlayingLoop = self.isPlayingLoop
    }
  }
  
  var loopExists = false {
    didSet {
      self.loopPlaybackDelegate?.loopExists = self.loopExists
    }
  }
  
  var loopStartTime: UInt64 {
    return self.internalLoopStartTime ?? self.loopService.currentLoopStartTime!
  }
  
  var hasAudio: Bool {
    return self.audioPlayer != nil
  }
  
  var audioFileURL: URL {
    get {
      let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
      let documentsDirectory = paths[0]
      let audioFilePath = (documentsDirectory as NSString).appendingPathComponent("\(self.uuid).caf")
      return URL(fileURLWithPath: audioFilePath)
    }
  }
  
  var muted = false {
    didSet {
      if self.muted {
        self.currentVolumeLevel = self.volumeLevel;
        self.volumeLevel = 0
      } else {
        self.volumeLevel = self.currentVolumeLevel
      }
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
      AVSampleRateKey: NSNumber(value: 44100.0 as Float),
      AVNumberOfChannelsKey: NSNumber(value: 1 as Int32),
      AVLinearPCMBitDepthKey: NSNumber(value: 16 as Int32),
      AVLinearPCMIsBigEndianKey: NSNumber(value: false as Bool),
      AVLinearPCMIsFloatKey: NSNumber(value: false as Bool)
      ] as [String : Any]
    
    self.playbackQueue.maxConcurrentOperationCount = 1
    
    do {
      self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL, settings: recordSettings)
      self.audioRecorder.delegate = self
      self.audioRecorder.prepareToRecord()
      self.audioRecorder.isMeteringEnabled = true
    } catch let error as NSError {
      print("There was a problem setting play and record audio session category: \(error.localizedDescription)")
    }
  }
  
  func recordAudio() {
    if !self.audioRecorder.isRecording {
      self.clearLoop()
      self.audioRecorder.record()
      self.playbackDelegate?.audioURL = nil
      self.recordDelegate?.isRecording = true
      self.loopRecordDelegate?.enabled = false
      self.trackAccessDelegate?.enabled = false
      if self.meterTimer == nil {
        self.meterTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(TrackService.updateMeters), userInfo: nil, repeats: true)
        RunLoop.main.add(self.meterTimer!, forMode: RunLoopMode.commonModes)
      }
      self.loopPlaybackDelegate?.loopExists = false
    }
  }
  
  func playAudioWithStartPercent(_ percent: Double) {
    if let audioPlayer = self.audioPlayer {
      let audioTime = audioPlayer.duration * percent
      
      if self.isArmedForLoopRecord && !self.isLoopRecording { // first sample marks downbeat of 1 in loop in this case
        self.startLoopRecord()
      }
      
      if self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - self.loopStartTime,
          audioTime: audioTime,
          audioPlayer: audioPlayer))
      }
      
      audioPlayer.currentTime = audioTime
      audioPlayer.play()
      self.startCursorTimer()
    }
  }
  
  func stopAudio() {
    if self.audioRecorder.isRecording {
      self.audioRecorder.stop()
      self.recordDelegate?.isRecording = false
      self.meterTimer?.invalidate()
      self.meterTimer = nil
      self.meterDelegate?.dbLevel = nil
      self.trackAccessDelegate?.enabled = true
    } else if let audioPlayer = self.audioPlayer , audioPlayer.isPlaying {
      if self.isLoopRecording {
        self.loopPoints.append(LoopPoint(
          intervalFromStart: mach_absolute_time() - self.loopStartTime,
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
    self.loopService.currentlyRecordingTrackService = self
    
    let currentTime = mach_absolute_time()
    self.internalRecordStartTime = currentTime
    if self.loopService.currentLoopStartTime == nil { // this is the first recorded loop, making it the master track, begins with internal loopStartTime
      self.internalLoopStartTime = currentTime
    }
  }
  
  func finishLoopRecord() {
    if let audioPlayer = self.audioPlayer {
      self.loopPoints.append(LoopPoint(
        intervalFromStart: mach_absolute_time() - self.loopStartTime,
        audioTime: nil,
        audioPlayer: audioPlayer))
    }
    self.isLoopRecording = false
    self.loopExists = true
    self.addToLoopPlayback()
    self.loopService.currentlyRecordingTrackService = nil
  }
  
  func addToLoopPlayback() {
    self.isPlayingLoop = true
    self.startCursorTimer()
    
    self.loopService.addLoopPoints(self.loopPoints, trackService: self)
    
    if !self.loopService.isPlayingLoop {
      self.loopService.startLoopPlayback()
    }
  }
  
  func removeFromLoopPlayback() {
    if self.loopService.activeTrackServices.contains(self) {
      self.isPlayingLoop = false
      self.loopService.removeLoopPoints(self.loopPoints, trackService: self)
      self.cursorTimer?.invalidate()
      self.cursorTimer = nil
      self.playbackDelegate?.removeCursor()
    }
  }
  
  func updateRecordTime(currentTime: UInt64) {
    if let internalRecordStartTime = self.internalRecordStartTime, let masterLoopLength = self.loopService.masterLoopLength {
      let currentRecordTime = currentTime - internalRecordStartTime
      let distance = currentRecordTime.distance(to: masterLoopLength)
      let distanceThreshold = 10000
      if distance < distanceThreshold && self.isLoopRecording {
        self.isLoopRecording = false
        DispatchQueue.main.async {
          self.finishLoopRecord()
          NotificationCenter.default.post(
            Notification(
              name: Notification.Name(rawValue: Constants.notificationEndLoopRecord),
              object: self,
              userInfo: nil
            )
          )
        }
      }
    }
  }
  
  func updateCurrentTime() {
    if let audioPlayer = self.audioPlayer {
      self.playbackDelegate?.currentTime = audioPlayer.currentTime
    }
  }
  
  func updateMeters() {
    self.audioRecorder.updateMeters()
    self.meterDelegate?.dbLevel = self.audioRecorder.averagePower(forChannel: 0)
  }
  
  fileprivate func startCursorTimer() {
    if self.cursorTimer == nil {
      let interval = 0.001
      self.cursorTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(TrackService.updateCurrentTime), userInfo: nil, repeats: true)
      self.cursorTimer?.tolerance = interval * 0.10
      RunLoop.main.add(self.cursorTimer!, forMode: RunLoopMode.commonModes)
    }
  }
  
  fileprivate func clearLoop() {
    self.removeFromLoopPlayback()
    self.isLoopRecording = false
    self.loopPoints.removeAll()
  }
  
  // MARK: AVAudioRecorderDelegate
  
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if flag {
      self.playbackDelegate?.audioURL = recorder.url
      self.loopRecordDelegate?.enabled = true
      do {
        try self.audioPlayer = AVAudioPlayer(contentsOf: self.audioRecorder.url)
        self.audioPlayer?.prepareToPlay()
      } catch let error as NSError {
        print("Error setting audio player URL: \(error.localizedDescription)")
      }
    }
  }
  
}
