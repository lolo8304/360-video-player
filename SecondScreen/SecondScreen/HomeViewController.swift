//
//  HomeViewController.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var satusView: UIImageView!
    @IBOutlet weak var nofConnectionLabel: UILabel!
    
    var timer = Timer()
    var lastNo: Int = 1
    var countNo: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.countNo = countImages()
        Connector.instance.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        let aSelector : Selector = #selector(HomeViewController.switchImage)
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: aSelector, userInfo: nil, repeats: true)
        Connector.instance.startServer()
        Connector.instance.refreshState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Connector.instance.delegate = nil
        timer.invalidate()
    }
    
    func switchImage() {
        var no: Int = lastNo
        repeat {
            no = Int(arc4random_uniform(UInt32(self.countNo)))
        } while (no == lastNo)
        DispatchQueue.main.async() { () -> Void in
            self.imageView.image = UIImage(named: "VR-\(no)")!
        }
        lastNo = no
    }
    
    func countImages() -> Int {
        var count: Int = -1
        var image: UIImage?
        repeat {
            count += 1
            image = UIImage (named: "VR-\(count)")
        } while (image != nil)
        return count
    }
    
    //MAK: actions
    
    @IBAction func playVideo(_ sender: UIButton) {
        //self.launchVideo(name: "demo", ext: "m4v")
        self.launchVideo(name: "DE-AXA-One_second_away-Final_v3_short_360", ext: "mp4")
        
    }

    
}

extension HomeViewController: ConnectorDelegate {
    func device() {
        
    }
    func statusChanged(started: Bool, server: ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int) {
        DispatchQueue.main.async() { () -> Void in
            if (started) {
                self.satusView.image = UIImage(named: "status-green")
            } else {
                self.satusView.image = UIImage(named: "status-green")
            }
            self.nofConnectionLabel.text = "\(connections)"
        }
    }

}
