//
//  WaveformView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/20/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class WaveformView: UIView {
  
  var totalSamples = 0
  var asset: AVURLAsset?
  var assetTrack: AVAssetTrack?
  var plotImageView: UIImageView!
  
  let noiseFloor = Float(-50.0)
  
  var audioURL: NSURL? {
    didSet {
      if let audioURL = self.audioURL {
        self.asset = AVURLAsset(URL: audioURL)
        self.assetTrack =  self.asset?.tracksWithMediaType(AVMediaTypeAudio).first!
        
        let audioFormatDescriptionRef = self.assetTrack!.formatDescriptions[0] as! CMAudioFormatDescriptionRef
        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescriptionRef).memory as AudioStreamBasicDescription
        self.totalSamples = Int(audioStreamBasicDescription.mSampleRate * (Double(self.asset!.duration.value) / Double(self.asset!.duration.timescale)))
        
        self.setNeedsLayout()
      }
    }
  }
  
  // MARK: Overrides
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let widthPixels = Int(self.frame.width * UIScreen.mainScreen().scale)
    let heightPixels = Int(self.frame.height * UIScreen.mainScreen().scale)
    
    self.downsampleAssetForWidth(widthPixels) { samples, maxSample in
      self.plotWithSamples(samples, maxSample: maxSample, imageHeight: heightPixels) { image in
        if self.plotImageView == nil {
          self.plotImageView = UIImageView()
          self.addSubview(self.plotImageView)
        }
        
        self.plotImageView.frame = self.bounds
        self.plotImageView.image = image
      }
    }
  }
  
  // MARK: Methods
  
  func plotWithSamples(samples: NSData, maxSample: Float, imageHeight: Int, done: ((UIImage) -> ())?) {
    let s = UnsafePointer<Float>(samples.bytes)
    let sampleCount = samples.length / 4
    let imageSize = CGSize(width: sampleCount, height: imageHeight)
    UIGraphicsBeginImageContext(imageSize)
    let context = UIGraphicsGetCurrentContext()
    
    CGContextSetShouldAntialias(context, false)
    CGContextSetAlpha(context, 0.5)
    CGContextSetLineWidth(context, 1)
    CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
    
    let sampleAdjustmentFactor = Float(imageHeight) / (maxSample - self.noiseFloor) / 2
    let halfImageHeight = Float(imageHeight) / 2
    
    for i in 0..<sampleCount {
      let sample: Float = s[i]
      var pixels = (sample - self.noiseFloor) * sampleAdjustmentFactor
      if pixels == 0 {
        pixels = 1
      }
      
      CGContextMoveToPoint(context, CGFloat(i), CGFloat(halfImageHeight - pixels))
      CGContextAddLineToPoint(context, CGFloat(i), CGFloat(halfImageHeight + pixels))
      CGContextStrokePath(context)
    }
    
    done?(UIGraphicsGetImageFromCurrentImageContext())
  }
  
  func downsampleAssetForWidth(widthInPixels: Int, done: ((NSData, Float) -> ())?) {
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
        var sampleMax = self.noiseFloor
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
              var sample = self.minMaxOrValue(self.decibel(rawData), min: Float(self.noiseFloor), max: 0)
              tally += sample
              tallyCount++
              
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
  
  func decibel(amplitude: Float) -> Float {
    return 20.0 * log10(abs(amplitude)/32767.0)
  }
  
  func minMaxOrValue(x: Float, min: Float, max: Float) -> Float {
    return x <= min ? min : (x >= max ? max : x)
  }
  
}

















