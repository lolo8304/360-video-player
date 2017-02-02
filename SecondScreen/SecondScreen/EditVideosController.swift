//
//  EditVideosController.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 22.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//
import Foundation
import UIKit
import PhotosUI
import SecondScreenShared

// https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started

import UIKit

class EditVideosController: UICollectionViewController, UIGestureRecognizerDelegate,
    UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var videosCollectionView: UICollectionView!
    let imagePickerController = UIImagePickerController()
    var video: Video?
    

    var appDelegate:AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    var content:Content {
        return Content.instance
    }
    public func videos() -> [Video] {
        return self.content.videos
    }
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "VideoCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var standardColor: UIColor = UIColor.red;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videosCollectionView.delegate = self
        self.videosCollectionView.dataSource = self
        self.videosCollectionView.reloadData()
        self.video = nil
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //1
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //2
    override func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.videos().count
    }
    
    //3
    override func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UIVideoCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UIVideoCollectionViewCell
        //cell.backgroundColor = UIColor.black
        
        let nameLabel = cell.contentView.viewWithTag(10) as? UILabel
        //let mediaNameLabel = cell.contentView.viewWithTag(20) as? UILabel
        let languageImageView = cell.contentView.viewWithTag(30) as? UIImageView
        let versionLabel = cell.contentView.viewWithTag(40) as? UILabel
        let timeLabel = cell.contentView.viewWithTag(50) as? UILabel
        
        let video: Video = self.videos()[indexPath.item]
        cell.video = video
        
        //mediaNameLabel?.text = video.mediaURLString
        nameLabel?.text = video.name
        timeLabel?.text = video.durationInSeconds.fromSecToTime()
        versionLabel?.text = video.version
        
        DispatchQueue.main.async() { () -> Void in
            languageImageView?.image = UIImage(named: (video.language?.languageFlag())!)
        }
        
        //device.firstUIImage(view: imageView!)
        
        let gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        let aSelector : Selector = #selector(EditVideosController.longPress(_:))
        gesture.addTarget(self, action: aSelector)
        gesture.delegate = self;
        gesture.delaysTouchesBegan = true;
        cell.addGestureRecognizer(gesture)
        
        return cell
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _ = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UIVideoCollectionViewCell
        
        let video: Video = self.videos()[indexPath.item]
        
        self.launchVideo(device: nil, url: video.mediaURL(), playerDelegate: video)
        //        performSegue(withIdentifier: "PlayDevice", sender: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        self.standardColor = cell.backgroundColor!
        cell.backgroundColor = UIColor.red
    }
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        _ = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        //cell.backgroundColor = self.standardColor
    }
    
    
    
    @IBAction func addVideo(_ sender: UIBarButtonItem) {
    }
    @IBAction func refreshItems(_ sender: UIBarButtonItem) {
        Content.instance.reset()
        self.videosCollectionView.reloadData()
    }
    

    public func previewImageFromVideo(url:NSURL) -> UIImage? {
        let asset = AVAsset(url: url as URL)
        let imageGenerator = AVAssetImageGenerator(asset:asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value,2)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            return nil
        }
    }

    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UIBarButtonItem) {
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        imagePickerController.videoQuality = .typeHigh
        present(imagePickerController, animated: true, completion: nil)
     }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let videoNSURL = info["UIImagePickerControllerReferenceURL"] as! NSURL
        let videoURL = URL(string: videoNSURL.absoluteString!)
        let newVideo = Video(context: managedObjectContext).from(name: "new", mediaURL: videoURL!, mediaExt: videoURL!.pathExtension, language: "DE", duratinInS: 1000, sizeInBytes: 1000)
        Content.instance.addNewVideo(newVideo)
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePickerController.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            let cell: UIVideoCollectionViewCell = sender.view as! UIVideoCollectionViewCell
            self.video = cell.video
            
            /*
             let alert = UIAlertController(title: "Alert", message: "Edit mode is not implemented yet", preferredStyle: UIAlertControllerStyle.alert)
             alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
             self.present(alert, animated: true, completion: nil)
             */
            //performSegue(withIdentifier: "AddEditDevice", sender: nil)
            performSegue(withIdentifier: "EditVideo", sender: sender)
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "EditVideo") {
            let controller: EditVideoViewController = segue.destination as! EditVideoViewController
            controller.video = self.video
        }
    }
    
}

