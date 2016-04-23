//
//  PlaybackService.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/6/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import AVFoundation

class LoopService {
  
  static let sharedInstance = LoopService()
  
  private let playbackQueue = NSOperationQueue()
  private var loopPoints = [LoopPoint]()
  private var activeTrackServices = [TrackService]()
  private var audioPlayersPendingRemoval = [AVAudioPlayer]()
  
  var isPlayingLoop = false
  var currentLoopStartTime: UInt64?
  
  var hasLoopPoints: Bool {
    get {
      return self.loopPoints.count > 0
    }
  }
  
  var muteAll = false {
    didSet {
      for trackService in self.activeTrackServices {
        trackService.muted = self.muteAll
      }
    }
  }
  
  weak var masterTrackService: TrackService?
  weak var currentlyRecordingTrackService: TrackService?
  
  func addLoopPoints(loopPointsToAdd: [LoopPoint], trackService: TrackService) {
    var loopPoints = self.loopPoints
    loopPoints += loopPointsToAdd
    self.loopPoints = loopPoints.sort { a, b in
      a.intervalFromStart < b.intervalFromStart
    }
    self.activeTrackServices.append(trackService)
  }
  
  func removeLoopPoints(loopPointsToRemove: [LoopPoint], trackService: TrackService) {
    self.loopPoints = self.loopPoints.filter { loopPoint in
      for loopPointToRemove in loopPointsToRemove {
        if loopPointToRemove.uuid == loopPoint.uuid {
          return false
        }
      }
      return true
    }
    
    if let audioPlayer = loopPointsToRemove.first?.audioPlayer {
      self.audioPlayersPendingRemoval.append(audioPlayer)
    }
    
    if self.loopPoints.count == 0 {
      self.pauseLoopPlayback()
    }
    
    if let index = self.activeTrackServices.indexOf(trackService) {
      self.activeTrackServices.removeAtIndex(index)
    }
  }
  
  func startLoopPlayback() {
    self.isPlayingLoop = true
    var loopPoints = self.loopPoints
    self.playbackQueue.addOperationWithBlock {
      var i = 0
      self.audioPlayersPendingRemoval.removeAll()
      self.currentLoopStartTime = mach_absolute_time()
      repeat {
        if self.loopPoints.count == 0 {
          self.pauseLoopPlayback()
        } else if i < loopPoints.count {
          let loopPoint = loopPoints[i]
          if let currentLoopStartTime = self.currentLoopStartTime {
            let intervalFromStart = mach_absolute_time() - currentLoopStartTime
            if  intervalFromStart >= loopPoint.intervalFromStart {
              if let audioTime = loopPoint.audioTime {
                if self.audioPlayersPendingRemoval.indexOf(loopPoint.audioPlayer) == nil {
                  loopPoint.audioPlayer.currentTime = audioTime
                  loopPoint.audioPlayer.play()
                } else {
                  loopPoint.audioPlayer.pause()
                }
              } else {
                loopPoint.audioPlayer.pause()
              }
              i += 1
            }
          } else {
            break
          }
        } else {
          i = 0
          loopPoints = self.loopPoints
          self.audioPlayersPendingRemoval.removeAll()
          self.currentLoopStartTime = mach_absolute_time()
        }
      } while (self.isPlayingLoop)
      for loopPoint in loopPoints {
        loopPoint.audioPlayer.pause()
      }
      self.currentLoopStartTime = nil
      self.masterTrackService = nil
    }
  }
  
  func pauseLoopPlayback() {
    self.isPlayingLoop = false
  }
  
}