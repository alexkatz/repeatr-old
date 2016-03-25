//
//  WaveformView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/20/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class WaveformView: UIView, PlaybackDelegate, MeterDelegate {
  
  private var totalSamples = 0
  private var asset: AVURLAsset?
  private var assetTrack: AVAssetTrack?
  private var cursor: UIView?
  private var meterHeightConstraint: NSLayoutConstraint?
  private var bookmarkViews = [BookmarkView]()
  private var uncommittedBookmarkView: BookmarkView?
  private var activeTouch: UITouch?
  
  private lazy var plotImageView: UIImageView = { [unowned self] in
    let plotImageView = UIImageView()
    plotImageView.alpha = 0
    self.insertSubview(plotImageView, atIndex: 0)
    return plotImageView
    }()
  
  private lazy var meterView: UIView = { [unowned self] in
    let meterView = UIView()
    meterView.backgroundColor = Constants.blackColorTransparent
    meterView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(meterView)
    
    let horizontalConstraint = meterView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor)
    let verticalConstraint = meterView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor)
    let widthConstraint = meterView.widthAnchor.constraintEqualToAnchor(self.widthAnchor)
    var heightConstraint = meterView.heightAnchor.constraintEqualToAnchor(nil, constant: 0)
    NSLayoutConstraint.activateConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
    
    self.meterHeightConstraint = heightConstraint
    
    return meterView
    }()
  
  private lazy var bookmarkBaseView: UIView = { [unowned self] in
    let bookmarkBaseView = UIView()
    bookmarkBaseView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
    bookmarkBaseView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(bookmarkBaseView)
    
    let horizontal =  bookmarkBaseView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor)
    let vertical = bookmarkBaseView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor)
    let width = bookmarkBaseView.widthAnchor.constraintEqualToAnchor(self.widthAnchor)
    let height = bookmarkBaseView.heightAnchor.constraintEqualToAnchor(nil, constant: CGFloat(Constants.recordButtonHeight))
    
    NSLayoutConstraint.activateConstraints([horizontal, vertical, width, height])
    
    return bookmarkBaseView
    }()
  
  var audioURL: NSURL? {
    didSet {
      if let audioURL = self.audioURL {
        self.asset = AVURLAsset(URL: audioURL)
        self.assetTrack =  self.asset?.tracksWithMediaType(AVMediaTypeAudio).first!
        
        let audioFormatDescriptionRef = self.assetTrack!.formatDescriptions[0] as! CMAudioFormatDescriptionRef
        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescriptionRef).memory as AudioStreamBasicDescription
        self.totalSamples = Int(audioStreamBasicDescription.mSampleRate * (Double(self.asset!.duration.value) / Double(self.asset!.duration.timescale)))
        
        self.setNeedsLayout()
        UIView.animateWithDuration(Constants.defaultAnimationDuration) {
          self.plotImageView.alpha = 1
          self.bookmarkBaseView.alpha = 1
        }
      } else {
        self.plotImageView.alpha = 0
        self.bookmarkBaseView.alpha = 0
        self.asset = nil
        self.assetTrack = nil
      }
    }
  }
  
  var currentTime: NSTimeInterval? {
    didSet {
      if let currentTime = self.currentTime {
        if let asset = self.asset {
          self.setCursorPositionWithPercent(CGFloat(currentTime / asset.duration.seconds))
        }
      } else {
        self.removeCursor()
      }
    }
  }
  
  var dbLevel: Float? {
    didSet {
      if let dbLevel = self.dbLevel {
        self.meterView.alpha = 0.3
        let noiseFloor = 0 - AudioService.sharedInstance.noiseFloor
        let heightPercent = CGFloat((noiseFloor - abs(dbLevel)) / noiseFloor)
        self.meterHeightConstraint?.constant = heightPercent > 0 ? (self.bounds.height / 2) * heightPercent : 0
      } else {
        self.meterView.alpha = 0
      }
    }
  }
  
  // MARK: inits
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  // MARK: Overrides
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let widthPixels = Int(self.frame.width * UIScreen.mainScreen().scale)
    let heightPixels = Int(self.frame.height * UIScreen.mainScreen().scale)
    
    self.downsampleAssetForWidth(widthPixels) { samples, maxSample in
      self.plotWithSamples(samples, maxSample: maxSample, imageHeight: heightPixels) { image in
        self.plotImageView.frame = self.bounds
        self.plotImageView.image = image
      }
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.activeTouch = touches.maxElement { a, b -> Bool in
      a.timestamp > b.timestamp
    }
    
    if let location = self.activeTouch?.locationInView(self) {
      if self.bookmarkBaseView.frame.contains(location) {
        if let bookmarkView = self.bookmarkViews.filter({ $0.frame.contains(location) }).first {
          self.uncommittedBookmarkView = bookmarkView
        } else {
          self.bookmarkBaseView.backgroundColor = Constants.blackColorDarkerTransparent
          let bookmarkView = self.createBookmarkAtLocation(location)
          self.bookmarkViews.append(bookmarkView)
          self.uncommittedBookmarkView = bookmarkView
        }
      } else {
        if self.bookmarkViews.count == 0 {
          let percent = Double(location.x / self.bounds.width)
          AudioService.sharedInstance.play(startPercent: percent)
        } else {
          let currentX = location.x
          var startPercent: Double?
          var previousBookmarkPercent: CGFloat?
          for bookmarkView in self.bookmarkViews {
            if let percent = bookmarkView.percentX {
              if let previousBookmarkPercent = previousBookmarkPercent {
                
              } else {
                previousBookmarkPercent = percent
              }
            }
          }
        }
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let uncommittedBookmarkView = self.uncommittedBookmarkView {
      if let location = touches.first?.locationInView(self) {
        uncommittedBookmarkView.center = CGPoint(x: location.x, y: uncommittedBookmarkView.center.y)
        UIView.animateWithDuration(Constants.defaultAnimationDuration) {
          uncommittedBookmarkView.alpha = location.y > self.bounds.height ? 0.2 : 1
        }
      }
    } else {
      
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.activeTouch != nil && touches.contains(self.activeTouch!) {
      AudioService.sharedInstance.stop()
      self.activeTouch = nil
      if self.bookmarkBaseView.backgroundColor != Constants.blackColorTransparent {
        UIView.animateWithDuration(Constants.defaultAnimationDuration) {
          self.bookmarkBaseView.backgroundColor = Constants.blackColorTransparent
        }
      }
      
      if let uncommittedBookmarkView = self.uncommittedBookmarkView {
        if uncommittedBookmarkView.alpha < 1 {
          uncommittedBookmarkView.removeFromSuperview()
          if let index = self.bookmarkViews.indexOf(uncommittedBookmarkView) {
            self.bookmarkViews.removeAtIndex(index)
          }
        }
        self.uncommittedBookmarkView = nil
      }
    }
  }
  
  // MARK: Methods
  
  func createBookmarkAtLocation(location: CGPoint) -> BookmarkView {
    let bookmarkView = BookmarkView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 44, height: self.bounds.height)))
    bookmarkView.center = CGPoint(x: location.x, y: bookmarkView.center.y)
    self.addSubview(bookmarkView)
    return bookmarkView
  }
  
  func setCursorPositionWithPercent(percent: CGFloat) {
    if self.cursor == nil {
      self.cursor = UIView()
      self.cursor?.backgroundColor = Constants.blackColorTransparent
      self.addSubview(self.cursor!)
    }
    
    if self.cursor!.alpha == 0 {
      self.cursor?.alpha = 1
    }
    
    self.cursor?.frame = CGRect(x: self.bounds.width * percent, y: 0, width: 2, height: self.bounds.height)
  }
  
  func removeCursor() {
    self.cursor?.alpha = 0
  }
  
  func clear() {
    self.plotImageView.alpha = 0
  }
  
  private func setup() {
    self.multipleTouchEnabled = true
  }
  
  private func plotWithSamples(samples: NSData, maxSample: Float, imageHeight: Int, done: ((UIImage) -> ())?) {
    let s = UnsafePointer<Float>(samples.bytes)
    let sampleCount = samples.length / 4
    let imageSize = CGSize(width: sampleCount, height: imageHeight)
    UIGraphicsBeginImageContext(imageSize)
    let context = UIGraphicsGetCurrentContext()
    
    CGContextSetShouldAntialias(context, false)
    CGContextSetAlpha(context, 1)
    CGContextSetLineWidth(context, 1)
    CGContextSetStrokeColorWithColor(context, Constants.blackColorTransparent.CGColor)
    
    let sampleAdjustmentFactor = Float(imageHeight) / (maxSample - AudioService.sharedInstance.noiseFloor) / 2
    let halfImageHeight = Float(imageHeight) / 2
    
    for i in 0..<sampleCount {
      let sample: Float = s[i]
      var pixels = (sample - AudioService.sharedInstance.noiseFloor) * sampleAdjustmentFactor
      if pixels == 0 {
        pixels = 1
      }
      
      CGContextMoveToPoint(context, CGFloat(i), CGFloat(halfImageHeight - pixels))
      CGContextAddLineToPoint(context, CGFloat(i), CGFloat(halfImageHeight + pixels))
      CGContextStrokePath(context)
    }
    
    done?(UIGraphicsGetImageFromCurrentImageContext())
  }
  
  private func downsampleAssetForWidth(widthInPixels: Int, done: ((NSData, Float) -> ())?) {
    if let asset = self.asset, assetTrack = self.assetTrack {
      do {
        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: asset.duration.timescale), CMTime(seconds: Double(self.totalSamples), preferredTimescale: asset.duration.timescale))
        
        let outputSettings: [String: AnyObject] = [
          AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatLinearPCM),
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsBigEndianKey: false,
          AVLinearPCMIsFloatKey: false,
          AVLinearPCMIsNonInterleaved: false]
        let output = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.addOutput(output)
        
        let bytesPerInputSample = 2
        var sampleMax = AudioService.sharedInstance.noiseFloor
        var tally = Float(0)
        var tallyCount = Float(0)
        let downsampleFactor = Int(self.totalSamples / widthInPixels)
        let fullAudioData = NSMutableData(capacity: Int(asset.duration.value / Int64(downsampleFactor)) * 2)!
        
        reader.startReading()
        
        while reader.status == .Reading {
          let trackOutput = reader.outputs[0] as! AVAssetReaderTrackOutput
          if let sampleBufferRef = trackOutput.copyNextSampleBuffer(), blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef) {
            let bufferLength = CMBlockBufferGetDataLength(blockBufferRef)
            let data = malloc(bufferLength)
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data)
            
            let samples = UnsafeMutablePointer<Int16>(data)
            let sampleCount = bufferLength / bytesPerInputSample
            
            for i in 0..<sampleCount {
              let rawData = Float(samples[i])
              var sample = self.minMaxOrValue(self.decibel(rawData), min: Float(AudioService.sharedInstance.noiseFloor), max: 0)
              tally += sample
              tallyCount += 1
              
              if Int(tallyCount) == downsampleFactor {
                sample = tally/tallyCount
                sampleMax = sampleMax > sample ? sampleMax : sample
                fullAudioData.appendBytes(&sample, length: sizeofValue(sample))
                tally = 0
                tallyCount = 0
              }
              CMSampleBufferInvalidate(sampleBufferRef);
            }
          }
        }
        
        if reader.status == .Completed {
          done?(fullAudioData, sampleMax)
        }
      } catch {
        print("There was a problem downsampling the asset")
      }
    }
  }
  
  private func decibel(amplitude: Float) -> Float {
    return 20.0 * log10(abs(amplitude)/32767.0)
  }
  
  private func minMaxOrValue(x: Float, min: Float, max: Float) -> Float {
    return x <= min ? min : (x >= max ? max : x)
  }
  
}

















