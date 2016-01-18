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
import SwiftyDropbox

class SceneViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var sceneLabel: UIButton!
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet var sceneAddMediaButtons: Array<UIButton>!
    
    
    var sceneButtons              = [[UIButton]?]()

    //Button types
    let ADD_BUTTONS               = 0
    let SHOT1                     = 0, SHOT2 = 1, SHOT3 = 2, VOICEOVER = 3

    //let soundwaveView: FVSoundWaveView = FVSoundWaveView()
    var vpVC                      = AVPlayerViewController()
    let library                   = PHPhotoLibrary.sharedPhotoLibrary()

    var videoPlayer: AVPlayer!

    // Scene specific identifiers
    var shotSelectedSegueID       = "sceneShotSelectedSegue"
    var voiceOverSelectedSegueID  = "sceneVoiceOverSelectedSegue"
    var selectingShotSegueID      = "sceneSelectingShotSegue"
    var selectingVoiceOverSegueID = "sceneSelectingVoiceOverSegue"
    var sceneNumber:        Int!
    var index: Int!
    var assetRequestNumber: Int!
    var scene: Scene!

    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: NSURL!
    // placeholder values
    let defaultImage              = UIImage(named: "plus_white_69")
    let defaultVideoURL           = NSURL(string: "placeholder")
    let defaultVoiceOverFile      = "placeholder"
    
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        if Dropbox.authorizedClient != nil {
            MediaController.sharedMediaController.dropboxIsLoading = true
        } else {
            MediaController.sharedMediaController.dropboxIsLoading = false
        }
        // self.sceneAddMediaButtons.last?.addSubview(self.soundwaveView)
        
        for button in self.sceneAddMediaButtons {
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.grayColor().CGColor
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        MediaController.sharedMediaController.albumTitle = MediaController.Albums.scenes
        self.scene = MediaController.sharedMediaController.scenes[sceneNumber]
        
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoAsset = nil
            self.selectedVideoImage = nil
        }
        
        self.sceneButtons = [self.sceneAddMediaButtons]
        
        self.navigationController?.navigationBar.translucent = true
        self.setupView()
        self.sceneLabel.setTitle("  Scene \(self.sceneNumber + 1)", forState: .Normal)
        self.sceneLabel.setTitle("  Scene \(self.sceneNumber + 1)", forState: .Highlighted)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setupView() {
        defer {
            self.selectedVideoAsset = nil
            self.selectedVideoImage = nil
        }
        
        if assetRequestNumber != nil && self.selectedVideoAsset != nil && self.selectedVideoImage != nil {
            self.scene.shotImages[assetRequestNumber - 1] = self.selectedVideoImage
            self.scene.shotVideos[assetRequestNumber - 1] = self.selectedVideoAsset
            MediaController.sharedMediaController.saveScenes()
        }
        
        // Set button images
        for var i = 0; i < self.sceneButtons[ADD_BUTTONS]!.count; i++ {
            let images = self.scene.shotImages
            let videos = self.scene.shotVideos
            
            if images.count > i && videos[i] != self.defaultVideoURL {
                self.sceneButtons[ADD_BUTTONS]![i].setImage(images[i], forState: UIControlState.Normal)
                self.sceneButtons[ADD_BUTTONS]![i].contentMode = UIViewContentMode.ScaleAspectFit
                self.sceneButtons[ADD_BUTTONS]![i].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            }
        }
        
        // Access stored voiceover.
        let filePath = MediaController.sharedMediaController.getPathForFileInDocumentsDirectory(self.scene.voiceOver)
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath.path!) {
            MediaController.sharedMediaController.saveScenes()
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].highlighted = true
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].setTitle("", forState: .Highlighted)
        } else {
            self.scene.voiceOver = self.defaultVoiceOverFile
            MediaController.sharedMediaController.saveScenes()
        }
        self.checkForCompletedScene()
    }
    
    func checkForCompletedScene() {
        var completedShots = 0
        
        for shot in self.scene.shotVideos {
            if shot != self.defaultVideoURL {
                completedShots += 1
            }
        }
        
        if completedShots == 3 {
            self.sceneLabel.highlighted = true
        } else {
            self.sceneLabel.highlighted = false
        }

    }
    
    // MARK: Button Actions
    @IBAction func selectMedia(sender: UIButton) {
        self.assetRequestNumber = sender.tag
        let buttonPressed = sender.tag - 1
        
        if buttonPressed > SHOT3 {
            NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.voiceoverCalled, object: self)
        } else {
            self.performSegueWithIdentifier(self.selectingShotSegueID, sender: self)
            NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.selectShotCalled, object: self)
        }
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        defer {
            MediaController.sharedMediaController.preview = nil
        }
        
        MediaController.sharedMediaController.prepareMediaFor(scene: self.sceneNumber, movie: false, save: false)
        
        if let preview = MediaController.sharedMediaController.preview {
            self.videoPlayer = AVPlayer(playerItem: preview)
            self.vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            self.view.window?.rootViewController?.presentViewController(self.vpVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func saveScene(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "saveCompleted:",
            name: MediaController.Notifications.saveSceneFinished,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "saveFailed:",
            name: MediaController.Notifications.saveSceneFailed,
            object: nil)

        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6

        MediaController.sharedMediaController.prepareMediaFor(scene: self.sceneNumber, movie: false, save: true)
    }
    
    // MARK: Save notifications
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveSceneFailed,
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveSceneFinished,
            object: nil)
        
        var message: String
        
        if MediaController.sharedMediaController.dropboxIsLoading == false {
            message = "Scene saved to Photos!"
        } else {
            message = "Scene saved to Photos! Video is being uploaded to Dropbox. Please do not close the app until you are notified that it is complete"
        }
        
        let alertSuccess = UIAlertController(title: "Success", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertSuccess.addAction(okAction)
        self.presentViewController(alertSuccess, animated: true, completion: nil)
        MediaController.sharedMediaController.dropboxIsLoading = false
    }
    
    
    func saveFailed(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveSceneFinished,
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveSceneFailed,
            object: nil)
        
        let alertFailure = UIAlertController(
            title: "Failure",
            message: "Scene failed to save. Re-select media and try again", preferredStyle: .Alert)
        let okAction = UIAlertAction(
            title: "Thanks!",
            style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertFailure.addAction(okAction)
        self.presentViewController(alertFailure, animated: true, completion: nil)
    }
    
    // MARK: segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == selectingShotSegueID {
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.shotSelectedSegueID
            destinationVC.shotNumber = self.assetRequestNumber
        } else if segue.identifier == self.selectingVoiceOverSegueID {
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.sceneID = self.sceneNumber
            destinationVC.audioSaveID = "scene\(self.sceneNumber)"
        }
    }
    
    
    @IBAction func sceneShotUnwindSegue(unwindSegue: UIStoryboardSegue) {
        self.checkForCompletedScene()
    }
    
    @IBAction func sceneAudioUnwindSegue(unwindSegue: UIStoryboardSegue){
       
    }
}
