//
//  ViewController.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/19/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, TrackSelectorDelegate {
  
  private var selectedWaveformView: WaveformView?
  private var tracks = [Track]()
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var pageControl: UIPageControl!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var loopPlaybackView: LoopPlaybackView!
  @IBOutlet weak var trackAccessView: TrackAccessView!
  
  var scrollEnabled = false {
    didSet {
      self.collectionView.scrollEnabled = self.scrollEnabled
      UIView.animateWithDuration(Constants.defaultAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
        self.pageControl.alpha = self.scrollEnabled ? 1 : 0
        self.selectedWaveformView?.enabled = !self.scrollEnabled
        }, completion: nil)
    }
  }
  
  var isSelectingTrack = false {
    didSet {
      self.scrollEnabled = self.isSelectingTrack
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tracks.append(Track(audioService: AudioService()))
    
    self.pageControl.userInteractionEnabled = false
    self.pageControl.numberOfPages = self.tracks.count + 1
    self.pageControl.currentPage = 0
    
    self.trackAccessView.delegate = self
    
    self.collectionView.registerClass(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: String(WaveformCollectionViewCell))
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.scrollEnabled = false
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !(self.collectionView.collectionViewLayout is WaveformCollectionViewLayout) {
      self.setCollectionViewLayoutWithSize(self.collectionView.bounds.size)
      self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.pageControl.currentPage, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
      self.scrollEnabled = false
    }
  }
  
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    let newCollectionViewSize = CGSize(width: size.width, height: size.height - CGFloat(Constants.recordButtonHeight))
    
    coordinator.animateAlongsideTransition({ context in
      self.setCollectionViewLayoutWithSize(newCollectionViewSize)
      self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.pageControl.currentPage, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
      }, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  private func setCollectionViewLayoutWithSize(size: CGSize, animated: Bool = false) {
    let layout = WaveformCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.tracks.count + 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(WaveformCollectionViewCell), forIndexPath: indexPath) as! WaveformCollectionViewCell
    if indexPath.item < self.tracks.count {
      
      let track = self.tracks[indexPath.item]
      cell.waveformView = track.waveformView
      track.audioService.recordDelegate = self.recordView
      track.audioService.loopRecordDelegate = self.loopRecordView
      track.audioService.loopPlaybackDelegate = self.loopPlaybackView
      track.audioService.trackAccessDelegate = self.trackAccessView
      track.audioService.playbackDelegate = track.waveformView
      track.audioService.meterDelegate = track.waveformView

      self.recordView.audioService = track.audioService
      self.loopRecordView.audioService = track.audioService
      self.loopPlaybackView.audioService = track.audioService
      cell.waveformView?.audioService = track.audioService
      
      self.selectedWaveformView = track.waveformView
    } else {
      cell.title = "NEW TRACK"
    }
    
    return cell
  }
  
  // MARK: UIScrollViewDelegate
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    let pageWidth = self.collectionView.frame.width
    self.pageControl.currentPage = Int(self.collectionView.contentOffset.x / pageWidth);
  }
  
}

