//
//  AppDelegate.swift
//  SecondScreenFeature
//
//  Created by Lorenz Hänggi on 24.12.16.
//  Copyright © 2016 lolo. All rights reserved.
//

import UIKit
import CoreData

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
        if let shared = UserDefaults(suiteName: "group.com.vr-second-tv.share") {
            if let url: URL = shared.object(forKey: "shared.url") as? URL {
                let newVideo: Video = Video(context: managedObjectContext)
                newVideo.mediaURLString = url.absoluteString
                newVideo.language = shared.object(forKey: "shared.language") as? String
                newVideo.mediaExt = shared.object(forKey: "shared.media") as? String
                newVideo.version = shared.object(forKey: "shared.version") as? String
 //               shared.set(self.selected360Type, forKey: "shared.360-type")
                Content.instance.addNewVideo(newVideo)
                shared.removeObject(forKey: "shared.url")
                shared.synchronize()
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [ .landscapeRight,  .portrait ]
    }
}




extension UIViewController {
    
    func launchVideo(url: URL) {
        let videoController: HTY360PlayerVC = HTY360PlayerVC.init(nibName: "HTY360PlayerVC", bundle: nil, url: url)
        //self.dismiss(animated: true, completion: nil)
        self.present(videoController, animated: false, completion: nil)
    }
    func launchVideo(name: String, ext: String) {
        let videoController: HTY360PlayerVC = HTY360PlayerVC.init(nibName: "HTY360PlayerVC", bundle: nil, name: name, ext: ext)
        //self.dismiss(animated: true, completion: nil)
        self.present(videoController, animated: false, completion: nil)
    }

}


var applicationDocumentsDirectory: NSURL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count-1] as NSURL
}()



var managedObjectContext: NSManagedObjectContext = {
    let coordinator = persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
}()


var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
    let url = applicationDocumentsDirectory.appendingPathComponent("SecondScreen.sqlite")
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    } catch {
        var dict = [String: AnyObject]()
        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
        dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
        
        dict[NSUnderlyingErrorKey] = error as NSError
        let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
        NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        abort()
    }
    
    return coordinator
}()


var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
}()



