//
//  AppDelegate.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 24.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import UIKit
import CoreData
import SecondScreenShared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let connector: Connector = Connector.instance
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        Connector.instance.stopServer()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        Connector.instance.startServer()
        Content.instance.reload()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [ .landscapeRight, .portrait ]
    }
}




extension UIViewController {
    
    func launchVideo(device: Device?, url: URL, playerDelegate: HTY360PlayerVCDelegate) {
        let videoController: HTY360PlayerVC = HTY360PlayerVC.init(device?.player, nibName: "HTY360PlayerVC", bundle: nil, url: url)
        videoController.playerDelegate = playerDelegate;
        //self.dismiss(animated: true, completion: nil)
        self.present(videoController, animated: false, completion: nil)
    }
    func launchVideo(device: Device?, name: String, ext: String) {
        let videoController: HTY360PlayerVC = HTY360PlayerVC.init(device?.player, nibName: "HTY360PlayerVC", bundle: nil, name: name, ext: ext)
        //self.dismiss(animated: true, completion: nil)
        self.present(videoController, animated: false, completion: nil)
    }

}


extension Video : HTY360PlayerVCDelegate {
    public func videoPlayerTitle() -> String! {
        return "\(self.name) / \(self.version) / \(self.language)"
    }
    public func videoPlayerDuration(_ duration: Double) {
        let oldDuration = self.durationInSeconds
        let newDuration = Int64(duration)
        if (oldDuration != newDuration) {
            self.durationInSeconds = newDuration
            Content.instance.updateVideo(self)
        }
    }
    public func videoSaveSnapshot(_ image: UIImage!) {
        do {
            let uuid = UUID().uuidString
            let url = sharedApplicationDocumentsDirectory.appendingPathComponent("\(uuid).png")
            try UIImagePNGRepresentation(image)?.write(to: url!)
            self.previewURLString = url!.absoluteString
            Content.instance.updateVideo(self)
        } catch let anError {
            NSLog("error while writing UI image to file \(anError.localizedDescription)")
        }
    }
}


