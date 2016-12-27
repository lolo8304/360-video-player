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
        self.app.startServer(delegate: self)
        self.endPoint.text = self.app.socketServer?.endPoint()
    }
    
    @IBAction func stop(_ sender: UIButton) {
        self.app.stopServer()
    }
    
    public func showError(_ message: String, stack: Bool) {
        NSLog("message \(message)")
        if (stack) {
            for symbol: String in Thread.callStackSymbols {
                NSLog("%@", symbol)
            }
        }
    }
    
    public func appendLog(_ message: String) {
        count = count + 1
        if (count >= 30) {
            count = 0
            DispatchQueue.main.async() { () -> Void in
                self.logs.text = "\(message)"
            }
        } else {
            DispatchQueue.main.async() { () -> Void in
                self.logs.text = "\(message)\n\(self.logs.text!)"
            }
        }
        NSLog("message arrived: \(message)")
    }
    
    
    @IBAction func playVideo(_ sender: UIButton) {
        self.launchVideo(name: "demo", ext: "mv4")
    }
    func launchVideo(name: String, ext: String) {
        let path: String = Bundle.main.path(forResource: name, ofType: ext)!
        let url: URL = URL(fileURLWithPath: path)
        let videoController: HTY360PlayerVC = HTY360PlayerVC.init(nibName: "HTY360PlayerVC", bundle: nil, url: url)
        //self.dismiss(animated: true, completion: nil)
        self.present(videoController, animated: false, completion: nil)
    }


}

extension ViewController : PSWebSocketServerDelegate {
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
        self.appendLog(message as! String)
    }
    
    
    func serverDidStop(_ server: PSWebSocketServer!) {
    }
    func serverDidStart(_ server: PSWebSocketServer!) {
    }
    func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, webSocketDidFlushInput webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, webSocketDidFlushOutput webSocket: PSWebSocket!) {
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!) -> Bool {
        return true
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.showError("didCloseWithCode code=\(code), reason=\(reason)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!, address: Data!, trust: SecTrust!, response: AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>!) -> Bool {
        return true
    }
}
