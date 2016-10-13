//
//  WaveformView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/20/16
//  Copyright © 2016 Alexander Katz. All rights reserved.
//
// NOTE: waveform drawing influenced by: https://github.com/fulldecent/FDWaveformView
//

import UIKit
import AVFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class WaveformView: UIView, PlaybackDelegate, MeterDelegate {
  
  fileprivate var totalSamples = 0
  fileprivate var asset: AVURLAsset?
  fileprivate var assetTrack: AVAssetTrack?
  fileprivate var cursor: UIView?
  fileprivate var meterHeightConstraint: NSLayoutConstraint?
  fileprivate var bookmarkViews = [BookmarkView]()
  fileprivate var activeTouch: UITouch?
  fileprivate var isPlacingBookmark = false
  fileprivate var didInitialize = false
  fileprivate var hasAudio = false
  fileprivate var currentBounds: CGRect!
  fileprivate var uncommittedBookmarkDelta: CGFloat = 0
  
  fileprivate var uncommittedBookmarkView: BookmarkView?
  
  fileprivate lazy var plotImageView: UIImageView = self.createPlotImageView()
  fileprivate lazy var meterView: UIView = self.createMeterView()
  fileprivate lazy var bookmarkBaseView: UIView = self.createBookmarkBaseView()
  fileprivate lazy var label: UILabel = LayoutHelper.createInfoLabel()
  
  fileprivate var trackService: TrackService
  
  var audioURL: URL? {
    didSet {
      if let audioURL = self.audioURL {
        self.enabled = true
        self.asset = AVURLAsset(url: audioURL)
        self.assetTrack =  self.asset?.tracks(withMediaType: AVMediaTypeAudio).first!
        
        let audioFormatDescriptionRef = self.assetTrack!.formatDescriptions[0] as! CMAudioFormatDescription
        let audioStreamBasicDescription = (CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescriptionRef)?.pointee)! as AudioStreamBasicDescription
        self.totalSamples = Int(audioStreamBasicDescription.mSampleRate * (Double(self.asset!.duration.value) / Double(self.asset!.duration.timescale)))
        
        self.setNeedsLayout()
        self.drawWaveform()
        self.currentBounds = self.bounds
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
          self.plotImageView.alpha = 1
          self.bookmarkBaseView.alpha = 1
        })
        
      } else {
        self.clear()
        self.enabled = false
      }
    }
  }
  
  var currentTime: TimeInterval? {
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
        self.meterHeightConstraint?.constant = heightPercent > 0 ? self.bounds.height * heightPercent : 0
      } else {
        self.meterView.alpha = 0
      }
    }
  }
  
  var waveColor = UIColor.white.withAlphaComponent(0.5)
  var cursorColor = UIColor.white.withAlphaComponent(0.5) {
    didSet {
      self.cursor?.backgroundColor = self.cursorColor
    }
  }
  var bookmarkColor = UIColor.white.withAlphaComponent(0.5)
  var bookmarkBaseColor = UIColor.white.withAlphaComponent(0.5) {
    didSet {
      self.bookmarkBaseView.backgroundColor = self.bookmarkBaseColor
    }
  }
  var meterColor = UIColor.white.withAlphaComponent(0.5)
  
  var enabled = true {
    didSet {
      self.isUserInteractionEnabled = self.enabled
    }
  }
  
  var dimmed = false {
    didSet {
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
    if self.bounds != self.currentBounds {
      self.drawWaveform()
      self.currentBounds = self.bounds
    }
    
    self.label.removeFromSuperview()
    self.label.alpha = 0
    
    if !self.didInitialize && !self.hasAudio {
      self.didInitialize = true
      LayoutHelper.addInfoLabel(self.label, toView: self)
      self.label.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
      self.label.alpha = 1
      UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
        self.label.transform = CGAffineTransform(scaleX: 1, y: 1)
      })
    } else if !self.hasAudio {
      LayoutHelper.addInfoLabel(self.label, toView: self)
      self.label.alpha = 1
    }
    
    for bookmarkView in self.bookmarkViews {
      if let percentX = bookmarkView.percentX {
        bookmarkView.frame = CGRect(
          x: (self.bounds.width * percentX) - (Constants.bookmarkViewWidth / 2),
          y: 0,
          width: Constants.bookmarkViewWidth,
          height: self.bounds.height)
      }
    }
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil {
      self.addGestureRecognizer(WaveformGestureRecognizer(waveformView: self))
    } else {
      self.gestureRecognizers?.removeAll()
    }
  }
  
  // MARK: Methods
  
  func touchesBegan(_ touches: Set<UITouch>) {
    if touches.count == 1 {
      self.activeTouch = touches.first
    } else {
      self.activeTouch = touches.max { a, b -> Bool in
        a.timestamp > b.timestamp
      }
    }
    
    NotificationCenter.default.post(
      Notification(
        name: Notification.Name(rawValue: Constants.notificationTrackSelected),
        object: self,
        userInfo: [Constants.trackServiceUUIDKey: self.trackService.uuid]
      )
    )
    
    if let location = self.activeTouch?.location(in: self) {
      if self.bookmarkBaseView.frame.contains(location) && self.audioURL != nil {
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
          if let bookmarkView = self.bookmarkViews.filter({ $0.percentX < currentPercent }).last, let startPercent = bookmarkView.percentX {
            self.trackService.playAudioWithStartPercent(Double(startPercent))
          } else {
            self.trackService.playAudioWithStartPercent(0)
          }
        }
      }
    }
  }
  
  func touchesMoved(_ touches: Set<UITouch>) {
    if touches.filter({ $0 == self.activeTouch }).count == 0 {
      return
    }
    
    if let uncommittedBookmarkView = self.uncommittedBookmarkView {
      if let location = touches.first?.location(in: self), let previousLocation = touches.first?.previousLocation(in: self) {
        let deltaX = location.x - previousLocation.x
        
        self.uncommittedBookmarkDelta += abs(location.x - previousLocation.x)
        
        uncommittedBookmarkView.center = CGPoint(x: uncommittedBookmarkView.center.x + deltaX, y: uncommittedBookmarkView.center.y)
      }
    }
  }
  
  func touchesEnded(_ touches: Set<UITouch>) {
    if self.activeTouch != nil && touches.contains(self.activeTouch!) {
      if !self.trackService.isPlayingLoop {
        self.trackService.stopAudio()
      }
      
      self.activeTouch = nil
      
      if let uncommittedBookmarkView = self.uncommittedBookmarkView {
        if !self.isPlacingBookmark && self.uncommittedBookmarkDelta < 1 {
          uncommittedBookmarkView.isUserInteractionEnabled = false
          UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: [.beginFromCurrentState], animations: {
            uncommittedBookmarkView.alpha = 0
            }, completion: { finished in
              uncommittedBookmarkView.removeFromSuperview()
          })
          
          if let index = self.bookmarkViews.index(of: uncommittedBookmarkView) {
            self.bookmarkViews.remove(at: index)
          }
        }
        
        self.bookmarkViews.sort { a, b in
          a.percentX < b.percentX
        }
        
        self.uncommittedBookmarkView = nil
        self.isPlacingBookmark = false
        self.uncommittedBookmarkDelta = 0
      }
    }
  }
  
  func createBookmarkAtLocation(_ location: CGPoint) -> BookmarkView {
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
  
  func setCursorPositionWithPercent(_ percent: CGFloat) {
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
  
  fileprivate func setup() {
    self.isMultipleTouchEnabled = true
    self.cursor = UIView()
    self.cursor?.backgroundColor = self.cursorColor
    self.addSubview(self.cursor!)
    self.enabled = self.audioURL != nil
    
    let introText = "HOLD RECORD BELOW TO RECORD SOME AUDIO!"
    let range = (introText as NSString).range(of: " RECORD ")
    let attributedString = NSMutableAttributedString(string: introText)
    attributedString.addAttributes([NSForegroundColorAttributeName: Constants.redColor], range: range)
    self.label.attributedText = attributedString
  }
  
  fileprivate func drawWaveform() {
    let widthPixels = Int(self.frame.width * UIScreen.main.scale)
    let heightPixels = Int(self.frame.height * UIScreen.main.scale)
    
    self.downsampleAssetForWidth(widthPixels) { samples, maxSample in
      if let samples = samples, let maxSample = maxSample {
        self.plotWithSamples(samples, maxSample: maxSample, imageHeight: heightPixels) { image in
          self.plotImageView.frame = self.bounds
          self.plotImageView.image = image
        }
      }
    }
  }
  
  fileprivate func plotWithSamples(_ samples: Data, maxSample: Float, imageHeight: Int, done: ((UIImage?) -> ())?) {
    let s = (samples as NSData).bytes.bindMemory(to: Float.self, capacity: samples.count)
    let sampleCount = samples.count / 4
    let imageSize = CGSize(width: sampleCount, height: imageHeight)
    UIGraphicsBeginImageContext(imageSize)
    let context = UIGraphicsGetCurrentContext()
    
    context?.setShouldAntialias(false)
    context?.setAlpha(1)
    context?.setLineWidth(1)
    context?.setStrokeColor(self.waveColor.cgColor)
    
    let sampleAdjustmentFactor = Float(imageHeight) / (maxSample - self.trackService.noiseFloor) / 2
    let halfImageHeight = Float(imageHeight) / 2
    
    for i in 0..<sampleCount {
      let sample: Float = s[i]
      var pixels = (sample - self.trackService.noiseFloor) * sampleAdjustmentFactor
      if pixels == 0 {
        pixels = 1
      }
      
      context?.move(to: CGPoint(x: CGFloat(i), y: CGFloat(halfImageHeight - pixels)))
      context?.addLine(to: CGPoint(x: CGFloat(i), y: CGFloat(halfImageHeight + pixels)))
      context?.strokePath()
    }
    
    done?(UIGraphicsGetImageFromCurrentImageContext())
  }
  
  fileprivate func downsampleAssetForWidth(_ widthInPixels: Int, done: ((Data?, Float?) -> ())?) {
    if let asset = self.asset, let assetTrack = self.assetTrack , self.totalSamples > 0 && widthInPixels > 0 {
      do {
        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: asset.duration.timescale), CMTime(seconds: Double(self.totalSamples), preferredTimescale: asset.duration.timescale))
        
        let outputSettings: [String: AnyObject] = [
          AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM as UInt32),
          AVLinearPCMBitDepthKey: 16 as AnyObject,
          AVLinearPCMIsBigEndianKey: false as AnyObject,
          AVLinearPCMIsFloatKey: false as AnyObject,
          AVLinearPCMIsNonInterleaved: false as AnyObject]
        let output = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        
        let bytesPerInputSample = 2
        var sampleMax = self.trackService.noiseFloor
        var tally = Float(0)
        var tallyCount = Float(0)
        let downsampleFactor = Int(self.totalSamples / widthInPixels)
        let fullAudioData = NSMutableData(capacity: Int(asset.duration.value / Int64(downsampleFactor)) * 2)!
        
        reader.startReading()
        
        while reader.status == .reading {
          let trackOutput = reader.outputs[0] as! AVAssetReaderTrackOutput
          if let sampleBufferRef = trackOutput.copyNextSampleBuffer(), let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef) {
            let bufferLength = CMBlockBufferGetDataLength(blockBufferRef)
            if let data = malloc(bufferLength) {
              CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data)
              
              let samples = data.assumingMemoryBound(to: Int16.self)
              let sampleCount = bufferLength / bytesPerInputSample
              
              for i in 0..<sampleCount {
                let rawData = Float(samples[i])
                var sample = self.minMaxOrValue(self.decibel(rawData), min: Float(self.trackService.noiseFloor), max: 0)
                tally += sample
                tallyCount += 1
                
                if Int(tallyCount) == downsampleFactor {
                  sample = tally/tallyCount
                  sampleMax = sampleMax > sample ? sampleMax : sample
                  fullAudioData.append(&sample, length: MemoryLayout.size(ofValue: sample))
                  tally = 0
                  tallyCount = 0
                }
                CMSampleBufferInvalidate(sampleBufferRef);
              }
            }
          }
        }
        
        if reader.status == .completed {
          done?(fullAudioData as Data, sampleMax)
        }
      } catch let error as NSError {
        print("There was a problem downsampling the asset: \(error.localizedDescription)")
      }
    } else {
      done?(nil, nil)
    }
  }
  
  fileprivate func createBookmarkBaseView() -> UIView {
    let bookmarkBaseView = UIView()
    bookmarkBaseView.backgroundColor = self.bookmarkBaseColor
    bookmarkBaseView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(bookmarkBaseView)
    
    bookmarkBaseView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    bookmarkBaseView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    bookmarkBaseView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
    bookmarkBaseView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.20).isActive = true
    
    return bookmarkBaseView
  }
  
  fileprivate func createPlotImageView() -> UIImageView {
    let plotImageView = UIImageView()
    plotImageView.alpha = 0
    self.insertSubview(plotImageView, at: 0)
    return plotImageView
  }
  
  fileprivate func createMeterView() -> UIView {
    let meterView = UIView()
    meterView.backgroundColor = self.meterColor
    meterView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(meterView)
    
    meterView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    meterView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    meterView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
    let heightConstraint = meterView.heightAnchor.constraint(equalToConstant: 0)
    heightConstraint.isActive = true
    
    self.meterHeightConstraint = heightConstraint
    
    return meterView
  }
  
  fileprivate func decibel(_ amplitude: Float) -> Float {
    return 20.0 * log10(abs(amplitude)/32767.0)
  }
  
  fileprivate func minMaxOrValue(_ x: Float, min: Float, max: Float) -> Float {
    return x <= min ? min : (x >= max ? max : x)
  }
  
}

















