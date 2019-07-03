//
//  GuidedAudioDownloadingView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/22/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation
import ReactiveSwift

class GuidedAudioDownloadingView: UIView, URLSessionDownloadDelegate {
    
    fileprivate let downloadingLabel = UILabel.newAutoLayout()
    fileprivate let progressLabel = UILabel.newAutoLayout()
    
    fileprivate let guidedAudioModel: MindfulnessExerciseModel
    
    let progress:MutableProperty<Double> = MutableProperty(0.0)
    
    var backgroundSession:URLSession!
    
    var onComplete:((_ downloadedFileUrl:URL?)->Void)?
    
    init(guidedAudioModel: MindfulnessExerciseModel) {
        self.guidedAudioModel = guidedAudioModel
        
        super.init(frame: CGRect.zero)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.addSubview(self.progressLabel)
        self.progressLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        self.progressLabel.autoPinEdgeToSuperview(edge: .top)
        self.progressLabel.font = UIFont.gothamBook(32)
        self.progressLabel.textColor = UIColor.init(white: 0.1, alpha: 1.0)
        self.progressLabel.textAlignment = .center
        self.progressLabel.reactive.text <~ self.progress.producer.map({ (progress) in
            return "\(Int(progress * 100))%"
        })
        
        self.downloadingLabel.attributedText = "Downloading...".attributes(color: .white, font: UIFont.gothamBook(16), paragraphStyle: nil, tracking: 150.0)
        self.addSubview(self.downloadingLabel)
        self.downloadingLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        self.downloadingLabel.autoPin(edge: .top, to: .bottom, of: self.progressLabel, offset: 90.0)
        
        if let audioUrl = self.guidedAudioModel.assetUrl {
            self.startDownloading(url: audioUrl)
        }
    }
    
    func startDownloading(url: URL) {
        backgroundSession = URLSession.init(configuration: URLSessionConfiguration.background(withIdentifier: "backgroundSession"), delegate: self, delegateQueue: OperationQueue.main)
        let downloadTask = backgroundSession.downloadTask(with: url)
        
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let destinationUrl = self.guidedAudioModel.downloadUrlDestination() {
            do {
                try FileManager.default.moveItem(at: location, to: destinationUrl)
                self.complete(destinationUrl: destinationUrl)
            } catch {
                self.complete(destinationUrl: destinationUrl)
            }
        } else {
            self.complete(destinationUrl: nil)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.progress.value = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    }
    
    func complete(destinationUrl: URL?) {
        self.backgroundSession.finishTasksAndInvalidate()
        self.onComplete?(destinationUrl)
    }
}
