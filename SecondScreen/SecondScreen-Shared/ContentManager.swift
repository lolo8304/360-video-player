//
//  ContentManager.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import Foundation
import CoreData

public class ContentManager : NSObject {
    public static let instance: ContentManager = {
        return ContentManager()
    }()
    
    private override init() {
    }
    
    
    public func runningInAppExtension() -> Bool {
        // Check where we're running so that we can observe the right notification. This prevents
        // notifying anyone of their own changes.
        if (Bundle.main.infoDictionary?["NSExtension"] == nil) {
            return false
        } else {
            return true
        }
    }


}


public var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle(for: ContentManager.self).url(forResource: "Model", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
}()


public var applicationDocumentsDirectory: NSURL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count-1] as NSURL
}()

public var sharedApplicationDocumentsDirectory: NSURL = {
    let url: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vr-second-tv.share")!
    return NSURL(string: url.absoluteString)!
}()
/*
 NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.atomicbird.demonotes"];
*/

public var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
    let url = sharedApplicationDocumentsDirectory.appendingPathComponent("SecondScreen.sqlite")
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


public var managedObjectContext: NSManagedObjectContext = {
    let coordinator = persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
}()

