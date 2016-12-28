//
//  ViewController.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 24.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endPoint: UILabel!
    @IBOutlet weak var logs: UITextView!
    var count: Int = 0
    
    var app:AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.start(self.startButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MAK: actions
    @IBAction func start(_ sender: UIButton) {
        self.app.connector.startServer()
        self.endPoint.text = self.app.connector.endPoint()
    }
    
    @IBAction func stop(_ sender: UIButton) {
        self.app.connector.stopServer()
        self.endPoint.text = self.app.connector.endPoint()
    }
    
}
