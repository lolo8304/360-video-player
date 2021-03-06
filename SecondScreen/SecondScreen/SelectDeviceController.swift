//
//  SelectDeviceController.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 18.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SecondScreenShared

// https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started

import UIKit

class SelectDeviceController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var devicesCollectionView: UICollectionView!
    
    var appDelegate:AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    var connector:Connector {
        return Connector.instance
    }
    public func devices() -> [Device] {
        return self.connector.sortedDevicesById()
    }
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "DeviceCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var standardColor: UIColor = UIColor.red;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.devicesCollectionView.delegate = self
        self.devicesCollectionView.dataSource = self
        self.devicesCollectionView.reloadData()
        Connector.instance.delegate = self
        Connector.instance.choose(device: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        let no: Int = Int(arc4random_uniform(UInt32(3)))+1
        let imageView = UIImageView(image: UIImage(named: "VR-\(no)")!)
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.25
        self.devicesCollectionView.backgroundView = imageView
         */
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Connector.instance.delegate = ConnectorNoDelegate()

    }
    
    //1
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //2
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.devices().count
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UIDeviceCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UIDeviceCollectionViewCell
        //cell.backgroundColor = UIColor.black
        
        let hostNameLabel = cell.contentView.viewWithTag(10) as? UILabel
        let nameLabel = cell.contentView.viewWithTag(20) as? UILabel
        let languageImageView = cell.contentView.viewWithTag(30) as? UIImageView
        let statusImageView = cell.contentView.viewWithTag(40) as? UIImageView
        let timeLabel = cell.contentView.viewWithTag(50) as? UILabel
        let versionLabel = cell.contentView.viewWithTag(60) as? UILabel
        
        let device: Device = self.devices()[indexPath.item]
        cell.device = device
        
        hostNameLabel?.text = device.name
        nameLabel?.text = device.player.name
        timeLabel?.text = device.player.positionTime()
        versionLabel?.text = device.player.video?.version
        
        DispatchQueue.main.async() { () -> Void in
            if (device.player.isPlaying()) {
                statusImageView?.image = UIImage(named: "player-play")
            } else if (device.player.isSynchronizing()){
                statusImageView?.image = UIImage(named: "player-refresh")
            } else {
                statusImageView?.image = UIImage(named: "player-pause")
            }
            languageImageView?.image = device.player.video!.languageUIImage()
        }
        
        //device.firstUIImage(view: imageView!)
        
        let gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        let aSelector : Selector = #selector(SelectDeviceController.longPress(_:))
        gesture.addTarget(self, action: aSelector)
        gesture.delegate = self;
        gesture.delaysTouchesBegan = true;
        cell.addGestureRecognizer(gesture)
        
        return cell
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _ = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        let device: Device = self.devices()[indexPath.item]
        self.connector.choose(device: device)
        device.play()
        if (device.player.video != nil) {
            self.launchVideo(device: device, url: device.player.video!.mediaURL(), playerDelegate: device.player.video!)
            //        performSegue(withIdentifier: "PlayDevice", sender: nil)
        } else {
            device.stop()
            let alert = UIAlertController(title: "Alert", message: "Player doesn't play any video", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        self.standardColor = cell.backgroundColor!
        cell.backgroundColor = UIColor.red
    }
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        _ = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        //cell.backgroundColor = self.standardColor
    }
    
    
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            let cell: UIDeviceCollectionViewCell = sender.view as! UIDeviceCollectionViewCell

            let alert = UIAlertController(title: "Alert", message: "Edit mode is not implemented yet", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            //performSegue(withIdentifier: "AddEditDevice", sender: nil)
            
        }
    }
    
    @IBAction func refreshItems(_ sender: UIBarButtonItem) {
        self.devicesCollectionView.reloadData()
    }    
    
}

extension SelectDeviceController : ConnectorDelegate {
    
    private func refreshDevice(device: Device) {
        var i: Int = 0
        for eachDevice: Device in self.devices() {
            if (eachDevice.id == device.id) {
                let path: IndexPath = IndexPath(item: i, section: 0)
                self.devicesCollectionView.reloadItems(at: [path])
                return
            }
            i += 1
        }
    }
    internal func playerUpdated(device: Device, player: DevicePlayer) {
        self.refreshDevice(device: device)
    }

    internal func sendAction(action: String, data: JSON) {
        
    }

    internal func statusChanged(started: Bool, server: ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int) {
        self.devicesCollectionView.reloadData()
        
    }

    internal func deviceSelected(device: Device) {
        self.refreshDevice(device: device)
    }
    func deviceDeselected(device: Device) {
        
    }
    func noDeviceSelected() {
        
    }

    internal func deviceDisconnected(device: Device) {
        self.refreshDevice(device: device)
    }

    internal func deviceConnected(device: Device) {
        self.refreshDevice(device: device)
    }

    
}
