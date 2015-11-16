//  Assisted by http://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
//  SceneBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit

class FirstSceneViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet var shotButtons: Array<UIButton>!
    @IBOutlet var removeMediaButtons: Array<UIButton>!
    @IBOutlet weak var recordVoiceOverButton: UIButton!
    @IBOutlet weak var voiceOverLabel: UILabel!
    
    var vpVC = AVPlayerViewController()
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    
    var videoPlayer: AVPlayer!
    
    let clipID = "s1ClipSelectedSegue"
    let audioID = "s1AudioSelectedSegue"
    var assetRequestNumber: Int!
    var scene: Scene!
    
    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: NSURL!
    // placeholder values
    let defaultImage = UIImage(named: "plus_white_69")
    let defaultURL = NSURL(string: "placeholder")
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        for button in removeMediaButtons {
            button.alpha = 0
            button.enabled = false
        }
        guard let scenes = MediaController.sharedMediaController.loadScenes() else {
            for _ in 0..<3 {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultURL!)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
            return
        }
        MediaController.sharedMediaController.scenes = scenes
    }
    
    override func viewWillAppear(animated: Bool) {
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoImage = nil
            self.selectedVideoAsset = nil
        }
        self.navigationController?.navigationBarHidden = true
        self.scene = MediaController.sharedMediaController.scenes[0]
        
        if assetRequestNumber != nil {
            self.scene.shotImages[assetRequestNumber - 1] = self.selectedVideoImage
            self.scene.shotVideos[assetRequestNumber - 1] = self.selectedVideoAsset
            MediaController.sharedMediaController.saveScenes()
        }
        
        for var i = 0; i < self.shotButtons.count ; i++ {
            let images = self.scene.shotImages
            let videos = self.scene.shotVideos
            if images.count > i && videos[i] != self.defaultURL {
                self.shotButtons[i].setImage(images[i], forState: UIControlState.Normal)
                self.shotButtons[i].imageView!.contentMode = UIViewContentMode.ScaleAspectFit
                self.shotButtons[i].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
                if shotButtons[i].currentImage != defaultImage {
                    self.removeMediaButtons[i].alpha = 1
                    self.removeMediaButtons[i].enabled = true
                }
            }
        }
        
        if self.scene.voiceOver != defaultURL {
            let check = UIImage(named: "Check")
            self.recordVoiceOverButton.setImage(check, forState: UIControlState.Normal)
            self.removeMediaButtons[3].alpha = 1
            self.removeMediaButtons[3].enabled = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Button Actions
    @IBAction func selectClip(sender: UIButton) {
        self.selectedVideoAsset = nil
        self.assetRequestNumber = sender.tag
        self.removeMediaButtons[sender.tag - 1].alpha = 1
        self.removeMediaButtons[sender.tag - 1].enabled = true
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func removeMedia(sender: AnyObject) {
        if sender.tag < 4 {
            self.scene.shotVideos[sender.tag - 1] = self.defaultURL!
            self.scene.shotImages[sender.tag - 1] = self.defaultImage!
            self.shotButtons[sender.tag - 1].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.shotButtons[sender.tag - 1].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.shotButtons[sender.tag - 1].setImage(self.scene.shotImages[sender.tag - 1], forState: UIControlState.Normal)
        } else if sender.tag == 4 {
            self.recordVoiceOverButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.recordVoiceOverButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.recordVoiceOverButton.setImage(self.defaultImage, forState: UIControlState.Normal)
            self.scene.voiceOver = self.defaultURL!
        }
        
        self.removeMediaButtons[sender.tag - 1].alpha = 0
        self.removeMediaButtons[sender.tag - 1].enabled = false
        MediaController.sharedMediaController.saveScenes()
    }
    
    @IBAction func recordVoiceOver(sender: AnyObject) {
        scene.voiceOver = defaultURL!
        self.audioAsset = nil
        self.removeMediaButtons[3].alpha = 1
        self.removeMediaButtons[3].enabled = true
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        MediaController.sharedMediaController.prepareMedia([self.scene], movie: false, save: false)
        if let preview = MediaController.sharedMediaController.preview {
            self.videoPlayer = AVPlayer(playerItem: preview)
            self.vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            presentViewController(vpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: MediaController.Notifications.saveSceneFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed:", name: MediaController.Notifications.saveSceneFailed, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.prepareMedia([self.scene], movie: false, save: true)
    }
    // MARK: Save notifications
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFailed, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFinished, object: nil)
        let alertSuccess = UIAlertController(title: "Success", message: "Scene saved to Photos!", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertSuccess.addAction(okAction)
        self.presentViewController(alertSuccess, animated: true, completion: nil)
    }
    
    func saveFailed(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFinished, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFailed, object: nil)
        let alertFailure = UIAlertController(title: "Failure", message: "Scene failed to save. Re-select media and try again", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertFailure.addAction(okAction)
        self.presentViewController(alertFailure, animated: true, completion: nil)
    }
    // MARK: segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "s1SelectClip" {
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.clipID
            destinationVC.shotNumber = self.assetRequestNumber
        } else if segue.identifier == "s1SelectAudio" {
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.segueID = self.audioID
        }
    }
    
    @IBAction func s1ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func s1AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            
            self.scene.voiceOver = self.audioAsset
            //MediaController.sharedMediaController.saveScenes()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
