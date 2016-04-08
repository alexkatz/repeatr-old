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
  
  private let playbackQueue = NSOperationQueue()
  private var loopPoints = [LoopPoint]()
  private var isPlayingLoop = false
  static let sharedInstance = LoopService()
  private var audioPlayersPendingRemoval = [AVAudioPlayer]()
  
  var currentLoopStartTime: UInt64?
  
  var masterTrack: TrackService?
  
  func addLoopPoints(loopPointsToAdd: [LoopPoint]) {
    var loopPoints = self.loopPoints
    loopPoints += loopPointsToAdd
    self.loopPoints = loopPoints.sort { a, b in
      a.intervalFromStart < b.intervalFromStart
    }
  }
  
  func removeLoopPoints(loopPointsToRemove: [LoopPoint]) {
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
          let intervalFromStart = mach_absolute_time() - self.currentLoopStartTime!
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
          i = 0
          loopPoints = self.loopPoints
          self.audioPlayersPendingRemoval.removeAll()
          self.currentLoopStartTime = mach_absolute_time()
        }
      } while (self.isPlayingLoop)
      for loopPoint in loopPoints {
        loopPoint.audioPlayer.pause()
      }
    }
  }
  
  func pauseLoopPlayback() {
    self.isPlayingLoop = false
    self.currentLoopStartTime = nil
  }
  
  
}