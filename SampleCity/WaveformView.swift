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
  
  private let bookmarkRemovalThresholdTime: UInt64 = 3500000
  
  private var totalSamples = 0
  private var asset: AVURLAsset?
  private var assetTrack: AVAssetTrack?
  private var cursor: UIView?
  private var meterHeightConstraint: NSLayoutConstraint?
  private var bookmarkViews = [BookmarkView]()
  private var activeTouch: UITouch?
  private var uncommittedBookmarkTime: UInt64?
  private var isPlacingBookmark = false
  private var didInitialize = false
  private var hasAudio = false
  
  private var uncommittedBookmarkView: BookmarkView? {
    didSet {
      if self.uncommittedBookmarkView != nil && oldValue == nil {
        self.uncommittedBookmarkTime = mach_absolute_time()
      } else if self.uncommittedBookmarkView == nil {
        self.isPlacingBookmark = false
      }
    }
  }
  
  private lazy var plotImageView: UIImageView = self.createPlotImageView()
  private lazy var meterView: UIView = self.createMeterView()
  private lazy var bookmarkBaseView: UIView = self.createBookmarkBaseView()
  private lazy var label: UILabel = LayoutHelper.createInfoLabel()
  
  private var trackService: TrackService
  
  var audioURL: NSURL? {
    didSet {
      if let audioURL = self.audioURL {
        self.enabled = true
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
        self.clear()
        self.enabled = false
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
        self.hasAudio = true
        self.label.removeFromSuperview()
        self.meterView.alpha = 1
        let noiseFloor = 0 - self.trackService.noiseFloor
        let heightPercent = CGFloat((noiseFloor - abs(dbLevel)) / noiseFloor)
        self.meterHeightConstraint?.constant = heightPercent > 0 ? (self.bounds.height / 2) * heightPercent : 0
      } else {
        self.meterView.alpha = 0
      }
    }
  }
  
  var waveColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
  var cursorColor = UIColor.whiteColor().colorWithAlphaComponent(0.5) {
    didSet {
      self.cursor?.backgroundColor = self.cursorColor
    }
  }
  var bookmarkColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
  var bookmarkBaseColor = UIColor.whiteColor().colorWithAlphaComponent(0.5) {
    didSet {
      self.bookmarkBaseView.backgroundColor = self.bookmarkBaseColor
    }
  }
  var meterColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
  
  var enabled = true {
    didSet {
      self.userInteractionEnabled = self.enabled
      self.alpha = self.enabled ? 1 : 0.5
      self.bookmarkBaseView.alpha = self.enabled && self.audioURL != nil ? 1 : 0
    }
  }
  
  // MARK: inits
  
  required init(trackService: TrackService) {
    self.trackService = trackService
    super.init(frame: CGRect.zero)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.trackService = TrackService()
    super.init(coder: aDecoder)
    self.setup()
  }
  
  // MARK: Overrides
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.drawWaveform()
    
    self.label.removeFromSuperview()
    self.label.alpha = 0
    
    if !self.didInitialize && !self.hasAudio {
      self.didInitialize = true
      LayoutHelper.addInfoLabel(self.label, toView: self)
      self.label.transform = CGAffineTransformMakeScale(0.3, 0.3)
      self.label.alpha = 1
      UIView.animateWithDuration(Constants.defaultAnimationDuration) {
        self.label.transform = CGAffineTransformMakeScale(1, 1)
      }
    } else if !self.hasAudio {
      LayoutHelper.addInfoLabel(self.label, toView: self)
      self.label.alpha = 1
    }
    
    for bookmarkView in self.bookmarkViews {
      if let percentX = bookmarkView.percentX where bookmarkView.bounds.height != self.bounds.height {
        bookmarkView.frame = CGRect(
          x: (self.bounds.width * percentX) - (Constants.bookmarkViewWidth / 2),
          y: 0,
          width: Constants.bookmarkViewWidth,
          height: self.bounds.height)
      }
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if touches.count == 1 {
      self.activeTouch = touches.first
    } else {
      self.activeTouch = touches.maxElement { a, b -> Bool in
        a.timestamp > b.timestamp
      }
    }
    
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(
      name: Constants.notificationTrackSelected,
      object: self,
      userInfo: [Constants.trackServiceUUIDKey: self.trackService.uuid]))
    
    if let location = self.activeTouch?.locationInView(self) {
      if self.bookmarkBaseView.frame.contains(location) && !self.bookmarkBaseView.hidden {
        self.bookmarkBaseView.backgroundColor = self.bookmarkBaseColor
        if let bookmarkView = self.bookmarkViews.filter({ $0.frame.contains(location) }).first {
          self.uncommittedBookmarkView = bookmarkView
        } else {
          let bookmarkView = self.createBookmarkAtLocation(location)
          self.uncommittedBookmarkView = bookmarkView
        }
      } else if !self.trackService.isPlayingLoop {
        if self.bookmarkViews.count == 0 {
          let percent = Double(location.x / self.bounds.width)
          self.trackService.playAudioWithStartPercent(percent)
        } else {
          let currentPercent = CGFloat(location.x / self.bounds.width)
          if let bookmarkView = self.bookmarkViews.filter({ $0.percentX < currentPercent }).last, startPercent = bookmarkView.percentX {
            self.trackService.playAudioWithStartPercent(Double(startPercent))
          } else {
            self.trackService.playAudioWithStartPercent(0)
          }
        }
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if touches.filter({ $0 == self.activeTouch }).count == 0 {
      return
    }
    
    if let uncommittedBookmarkView = self.uncommittedBookmarkView {
      if let location = touches.first?.locationInView(self), previousLocation = touches.first?.previousLocationInView(self) {
        let deltaX = location.x - previousLocation.x
        uncommittedBookmarkView.center = CGPoint(x: uncommittedBookmarkView.center.x + deltaX, y: uncommittedBookmarkView.center.y)
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.activeTouch != nil && touches.contains(self.activeTouch!) {
      if !self.trackService.isPlayingLoop {
        self.trackService.stopAudio()
      }
      
      self.activeTouch = nil
      
      if let uncommittedBookmarkView = self.uncommittedBookmarkView, uncommittedBookmarkTime = self.uncommittedBookmarkTime {
        if mach_absolute_time() - uncommittedBookmarkTime < self.bookmarkRemovalThresholdTime && !self.isPlacingBookmark {
          uncommittedBookmarkView.userInteractionEnabled = false
          UIView.animateWithDuration(Constants.defaultAnimationDuration, delay: 0, options: [.BeginFromCurrentState], animations: {
            uncommittedBookmarkView.alpha = 0
            }, completion: { finished in
              uncommittedBookmarkView.removeFromSuperview()
          })
          
          if let index = self.bookmarkViews.indexOf(uncommittedBookmarkView) {
            self.bookmarkViews.removeAtIndex(index)
          }
        }
        
        self.bookmarkViews.sortInPlace { a, b in
          a.percentX < b.percentX
        }
        
        self.uncommittedBookmarkView = nil
      }
    }
  }
  
  // MARK: Methods

  func createBookmarkAtLocation(location: CGPoint) -> BookmarkView {
    let bookmarkView = BookmarkView(
      frame: CGRect(
        x: location.x - (Constants.bookmarkViewWidth / 2),
        y: 0,
        width: Constants.bookmarkViewWidth,
        height: self.bounds.height))
    bookmarkView.color = self.bookmarkColor
    self.bookmarkViews.append(bookmarkView)
    self.addSubview(bookmarkView)
    self.isPlacingBookmark = true
    return bookmarkView
  }
  
  func setCursorPositionWithPercent(percent: CGFloat) {
    if self.cursor?.alpha == 0 {
      self.cursor?.alpha = 1
    }
    
    self.cursor?.frame = CGRect(x: self.bounds.width * percent, y: 0, width: 2, height: self.bounds.height)
  }
  
  func removeCursor() {
    self.cursor?.alpha = 0
  }
  
  func clear() {
    self.plotImageView.alpha = 0
    for bookmarkView in self.bookmarkViews {
      bookmarkView.removeFromSuperview()
    }
    self.bookmarkViews.removeAll()
    
    self.plotImageView.alpha = 0
    self.bookmarkBaseView.alpha = 0
    self.asset = nil
    self.assetTrack = nil
  }
  
  private func setup() {
    self.multipleTouchEnabled = true
    self.cursor = UIView()
    self.cursor?.backgroundColor = self.cursorColor
    self.addSubview(self.cursor!)
    self.enabled = self.audioURL != nil
    
    let introText = "HOLD RECORD BELOW TO RECORD SOME AUDIO, YOU PUNK."
    let range = (introText as NSString).rangeOfString(" RECORD ")
    let attributedString = NSMutableAttributedString(string: introText)
    attributedString.addAttributes([NSForegroundColorAttributeName: Constants.redColor], range: range)
    self.label.attributedText = attributedString
  }
  
  private func drawWaveform() {
    let widthPixels = Int(self.frame.width * UIScreen.mainScreen().scale)
    let heightPixels = Int(self.frame.height * UIScreen.mainScreen().scale)
    
    self.downsampleAssetForWidth(widthPixels) { samples, maxSample in
      if let samples = samples, maxSample = maxSample {
        self.plotWithSamples(samples, maxSample: maxSample, imageHeight: heightPixels) { image in
          self.plotImageView.frame = self.bounds
          self.plotImageView.image = image
        }
      }
    }
  }
  
  private func plotWithSamples(samples: NSData, maxSample: Float, imageHeight: Int, done: ((UIImage?) -> ())?) {
    let s = UnsafePointer<Float>(samples.bytes)
    let sampleCount = samples.length / 4
    let imageSize = CGSize(width: sampleCount, height: imageHeight)
    UIGraphicsBeginImageContext(imageSize)
    let context = UIGraphicsGetCurrentContext()
    
    CGContextSetShouldAntialias(context, false)
    CGContextSetAlpha(context, 1)
    CGContextSetLineWidth(context, 1)
    CGContextSetStrokeColorWithColor(context, self.waveColor.CGColor)
    
    let sampleAdjustmentFactor = Float(imageHeight) / (maxSample - self.trackService.noiseFloor) / 2
    let halfImageHeight = Float(imageHeight) / 2
    
    for i in 0..<sampleCount {
      let sample: Float = s[i]
      var pixels = (sample - self.trackService.noiseFloor) * sampleAdjustmentFactor
      if pixels == 0 {
        pixels = 1
      }
      
      CGContextMoveToPoint(context, CGFloat(i), CGFloat(halfImageHeight - pixels))
      CGContextAddLineToPoint(context, CGFloat(i), CGFloat(halfImageHeight + pixels))
      CGContextStrokePath(context)
    }
    
    done?(UIGraphicsGetImageFromCurrentImageContext())
  }
  
  private func downsampleAssetForWidth(widthInPixels: Int, done: ((NSData?, Float?) -> ())?) {
    if let asset = self.asset, assetTrack = self.assetTrack where self.totalSamples > 0 && widthInPixels > 0 {
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
        var sampleMax = self.trackService.noiseFloor
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
              var sample = self.minMaxOrValue(self.decibel(rawData), min: Float(self.trackService.noiseFloor), max: 0)
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
        print("There was a problem downsampling the asset: \(error)")
      }
    } else {
      done?(nil, nil)
    }
  }
  
  private func createBookmarkBaseView() -> UIView {
    let bookmarkBaseView = UIView()
    bookmarkBaseView.backgroundColor = self.bookmarkBaseColor
    bookmarkBaseView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(bookmarkBaseView)
    
    bookmarkBaseView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    bookmarkBaseView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    bookmarkBaseView.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
    bookmarkBaseView.heightAnchor.constraintEqualToAnchor(self.heightAnchor, multiplier: 0.20).active = true
    
    return bookmarkBaseView
  }
  
  private func createPlotImageView() -> UIImageView {
    let plotImageView = UIImageView()
    plotImageView.alpha = 0
    self.insertSubview(plotImageView, atIndex: 0)
    return plotImageView
  }
  
  private func createMeterView() -> UIView {
    let meterView = UIView()
    meterView.backgroundColor = self.meterColor
    meterView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(meterView)
    
    meterView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    meterView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
    meterView.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
    let heightConstraint = meterView.heightAnchor.constraintEqualToAnchor(nil, constant: 0)
    heightConstraint.active = true
    
    self.meterHeightConstraint = heightConstraint
    
    return meterView
  }
  
  private func decibel(amplitude: Float) -> Float {
    return 20.0 * log10(abs(amplitude)/32767.0)
  }
  
  private func minMaxOrValue(x: Float, min: Float, max: Float) -> Float {
    return x <= min ? min : (x >= max ? max : x)
  }
  
}

















