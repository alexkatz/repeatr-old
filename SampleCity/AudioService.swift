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
  
  private var audioPlayer: AVAudioPlayer?
  private var audioRecorder: AVAudioRecorder!
  private var playbackTimer: NSTimer?
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
  
  var isPlayingLoop = false
  
  weak var playbackDelegate: PlaybackDelegate?
  weak var recordDelegate: RecordDelegate?
  weak var meterDelegate: MeterDelegate?
  weak var loopRecordDelegate: LoopRecordDelegate?
  
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
      if self.playbackTimer == nil {
        let interval = 0.001
        self.playbackTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(AudioService.updateCurrentTime), userInfo: nil, repeats: true)
        self.playbackTimer?.tolerance = interval * 0.10
      }
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
      self.playbackTimer?.invalidate()
      self.playbackTimer = nil
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
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    dispatch_async(queue) {
      //      NSThread.setThreadPriority(1)
      //      repeat {
      //        for (i, loopPoint) in self.loopPoints.enumerate() {
      //          var elapsed: UInt64 = 0
      //          if let audioTime = loopPoint.audioTime { // play loopPoint
      //            elapsed = self.loopPoints[i + 1].intervalFromStart - loopPoint.intervalFromStart
      //            self.audioPlayer?.currentTime = audioTime
      //            self.audioPlayer?.play()
      //          } else { // stop loop point, should always pause play initiated by previous play loopPoint
      //            self.audioPlayer?.pause()
      //            if i < self.loopPoints.count - 1 {
      //              elapsed = self.loopPoints[i + 1].intervalFromStart - loopPoint.intervalFromStart
      //            }
      //          }
      //          if i < self.loopPoints.count - 1 {
      //            var info = mach_timebase_info(numer: 0, denom: 0)
      //            mach_timebase_info(&info)
      //            let base = UInt64(info.numer / info.denom)
      //            let seconds = Double(elapsed * base) / 1_000_000_000
      //            NSThread.sleepForTimeInterval(seconds)
      //          }
      //        }
      //      } while (false)
      
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
      } while (true)
    }
  }
  
  func loop() {
    
  }
  
  func stopLoop() {
    self.loopPoints.removeAll()
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