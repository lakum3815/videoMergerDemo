//
//  MergeVideoVC.swift
//  VideoMerger
//
//  Created by Hiren Patel on 15/04/19.
//  Copyright © 2019 Hiren Patel. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos
import AVFoundation
import AVKit

class MergeVideoVC: UIViewController {
    var firstAsset: AVAsset?
    var secondAsset: AVAsset?
    var audioAsset: AVAsset?
    var loadingAssetOne = false
    
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var thumbImageViewFirst: UIImageView!
    @IBOutlet var thumbImageViewSecond: UIImageView!

    @IBOutlet var btnLoadVideo1: UIButton!
    @IBOutlet var btnLoadVideo2: UIButton!
    @IBOutlet var btnMerge: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnLoadVideo1.clipsToBounds = true
        self.btnLoadVideo1.layer.cornerRadius = 25
        self.btnLoadVideo2.clipsToBounds = true
        self.btnLoadVideo2.layer.cornerRadius = 25
        self.btnMerge.clipsToBounds = true
        self.btnMerge.layer.cornerRadius = 25
    }

    func savedPhotosAvailable() -> Bool {
        guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return true }
        
        let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        return false
    }
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        // Cleanup assets
        activityMonitor.stopAnimating()
        firstAsset = nil
        secondAsset = nil
        audioAsset = nil
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else { return }
        
        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        // Ensure permission to access Photo Library
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            })
        } else {
            saveVideoToPhotos()
        }
    }
    
    @IBAction func loadAssetOne(_ sender: AnyObject) {
        if savedPhotosAvailable() {
            loadingAssetOne = true
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadAssetTwo(_ sender: AnyObject) {
        if savedPhotosAvailable() {
            loadingAssetOne = false
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
    @IBAction func loadAudio(_ sender: AnyObject) {
        let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "Select Audio"
        present(mediaPickerController, animated: true, completion: nil)
    }
    
    @IBAction func merge(_ sender: AnyObject) {
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }
        
        activityMonitor.startAnimating()
        VideoManager.shared.merge(arrayVideos: [firstAsset, secondAsset]) {[weak self] (outputURL, error) in
            if let error = error {
                print("Error:\(error.localizedDescription)")
            }
            else {
                if let url = outputURL {
                    self?.activityMonitor.stopAnimating()
                    
                    let saveVideoToPhotos = {
                        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }) { saved, error in
                            let success = saved && (error == nil)
                            let title = success ? "Success" : "Error"
                            let message = success ? "Video is saved to your gallery. Do you want to play it?" : "Failed to save video"
                            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            
                            if success == true {
                                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in
                                    self?.openPreviewScreen(url)
                                }))
                                alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: { _ in
                                }))
                            } else {
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                            }
                            self!.present(alert, animated: true, completion: nil)
                        }
                    }
                    // Ensure permission to access Photo Library
                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                        PHPhotoLibrary.requestAuthorization({ status in
                            if status == .authorized {
                                saveVideoToPhotos()
                            }
                        })
                    } else {
                        saveVideoToPhotos()
                    }
                }
            }
        }
    }
    
    @IBAction func mergeWithAnimation(_ sender: AnyObject) {
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }
        
        activityMonitor.startAnimating()
        VideoManager.shared.mergeWithAnimation(arrayVideos: [firstAsset, secondAsset]) {[weak self] (outputURL, error) in
            if let error = error {
                print("Error:\(error.localizedDescription)")
            }
            else {
                if let url = outputURL {
                    self?.activityMonitor.stopAnimating()
                    
                    let saveVideoToPhotos = {
                        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }) { saved, error in
                            let success = saved && (error == nil)
                            let title = success ? "Success" : "Error"
                            let message = success ? "Video is saved to your gallery. Do you want to play it?" : "Failed to save video"
                            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            
                            if success == true {
                                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in
                                    self?.openPreviewScreen(url)
                                }))
                                alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: { _ in
                                }))
                            } else {
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                            }
                            self!.present(alert, animated: true, completion: nil)
                        }
                    }
                    // Ensure permission to access Photo Library
                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                        PHPhotoLibrary.requestAuthorization({ status in
                            if status == .authorized {
                                saveVideoToPhotos()
                            }
                        })
                    } else {
                        saveVideoToPhotos()
                    }
                }
            }
        }
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
    
}

extension MergeVideoVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            else { return }
        
        let avAsset = AVAsset(url: url)
        var message = ""
        if loadingAssetOne {
            message = "Video one loaded"
            firstAsset = avAsset
            // !! check the error before proceeding
            thumbImageViewFirst.image = self.generateThumbnail(asset: firstAsset!)

        } else {
            message = "Video two loaded"
            secondAsset = avAsset
            thumbImageViewSecond.image = self.generateThumbnail(asset: secondAsset!)
        }
        picker.dismiss(animated: true) {
            let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func generateThumbnail(asset: AVAsset) -> UIImage? {
        do {
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}

extension MergeVideoVC: UINavigationControllerDelegate {
    
}

extension MergeVideoVC: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        dismiss(animated: true) {
            let selectedSongs = mediaItemCollection.items
            guard let song = selectedSongs.first else { return }
            
            let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            self.audioAsset = (url == nil) ? nil : AVAsset(url: url!)
            let title = (url == nil) ? "Asset Not Available" : "Asset Loaded"
            let message = (url == nil) ? "Audio Not Loaded" : "Audio Loaded"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
}

