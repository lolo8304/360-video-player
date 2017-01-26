//
//  Content.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 22.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import Foundation
import CoreData

extension JSON {

    public func getString(_ attribute: String) -> String {
        return self[attribute].stringValue
    }
    private func getInt(_ attribute: String) -> Int {
        return self[attribute].intValue
    }
    
    public func getAttrName() -> String {
        return self.getString("name")
    }
    public func getAttrMediaName() -> String {
        return self.getString("media-name")
    }
    public func getAttrMediaExt() -> String {
        return self.getString("media-ext")
    }
    public func getAttrLanguage() -> String {
        return self.getString("language")
    }
    public func getAttrDurationInSec() -> Int {
        return self.getInt("durationInS")
    }
    public func getAttrDuration() -> String {
        return self.getString("duration")
    }
    public func getAttrSizeInBytes() -> Int {
        return self.getInt("sizeInBytes")
    }
    
}

extension String {
    public func fromTimeToSeconds() -> Int {
        var timeArray: [String] = self.components(separatedBy: ":")
        return Int(timeArray[0])! * 60 + Int(timeArray[1])!
    }
    public func fromTimeToMilliseconds() -> Int {
        return self.fromTimeToSeconds() * 1000
    }
    func languageFlag() -> String {
        switch self {
        case "EN":
            return "GB"
        default:
            return self
        }
    }
    
}

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension Int64 {
    public func fromMillisecondToTime() -> String {
        return Int.fromMillisecondToTime(i: Int(self))
    }
    public func fromSecToTime() -> String {
        return Int.fromSecToTime(i: Int(self))
    }
    public func asSizePrettyPrint() -> String {
        return Int.asSizePrettyPrint(i: Int(self))
    }
}

extension Int {
    public func fromMillisecondToTime() -> String {
        return Int.fromMillisecondToTime(i: self)
    }
    public func fromSecToTime() -> String {
        return Int.fromSecToTime(i: self)
    }
    public func asSizePrettyPrint() -> String {
        return Int.asSizePrettyPrint(i: self)
    }
    
    fileprivate static func fromMillisecondToTime(i: Int) -> String {
        var seconds: Int = i / 1000
        let minutes: Int = seconds / 60
        seconds = seconds % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    fileprivate static func fromSecToTime(i: Int) -> String {
        var seconds: Int = i
        let minutes: Int = seconds / 60
        seconds = seconds % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    fileprivate static func asSizePrettyPrint(i: Int) -> String {
        let levels: [String] = [ "", "k", "M", "G", "T" ]
        var size: Double = Double(i)
        var index: Int = 0
        while (size > 1024.0) {
            size = size / 1024.0
            index += 1
        }
        return String(format: "%.1f \(levels[index])", size)
    }

}

class Content : NSObject {
    static let instance: Content = {
        return Content().load()
    }()
    
    public var videos: [Video] = []
    
    private override init() {
    }
    
    public func getVideo(name: String) -> Video? {
        for video in self.videos {
            if (video.name == name) { return video }
        }
        return nil;
    }
    
    public func addNewVideo(_ newVideo: Video) {
        do {
            self.videos.append(newVideo)
            try newVideo.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
    }
    public func removeVideo(_ video: Video) {
        self.videos.remove(object: video)
        video.delete()
    }
    
    public func load() -> Content {
        self.initializeDatabase()
        if (self.videos.count == 0) {
            return self.loadTestData()
        }
        return self
    }
    func reload() -> Content {
        for video in self.videos {
            video.delete()
        }
        self.videos = []
        return self.load()
    }
    
    private func initializeDatabase() {
        // Initialize Fetch Request
        let fetchRequest: NSFetchRequest = NSFetchRequest<Video>()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "Video", in: managedObjectContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        do {
            self.videos = try managedObjectContext.fetch(fetchRequest)
            print(self.videos)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    fileprivate func readFromFile(name: String, ext: String) -> Data {
        let path = Bundle.main.path(forResource: name, ofType: "json")
        do {
            return try String(contentsOfFile: path!).data(using: .utf8)!
        } catch {
            print(error)
            return "{ \"videos\" : [] }".data(using: .utf8)!
        }
    }
    
    fileprivate func loadTestData() -> Content {
        let testVideos: JSON = JSON(data: self.readFromFile(name: "videos", ext: "json"));
        self.videos = []
        for video in testVideos["videos"].arrayValue {
            let newVideo: Video = Video(context: managedObjectContext).from(json: video)
            self.addNewVideo(newVideo)
        }
        return self
    }

}

extension Video {
    
    func delete() {
        do {
            managedObjectContext?.delete(self)
            try managedObjectContext?.save()
        } catch {
            print(error)
        }
        
    }
    
    public func mediaURL() -> URL {
        return URL(string: self.mediaURLString!)!
    }
    
    public func from(json: JSON) -> Video {
        self.name = json.getAttrName()
        self.mediaURLString = json.getAttrMediaName()
        self.mediaExt = json.getAttrMediaExt()
        self.language = json.getAttrLanguage()
        self.durationInSeconds = Int64(json.getAttrDuration().fromTimeToSeconds())
        self.sizeInBytes = Int64(json.getAttrSizeInBytes())
        return self
    }
    public func from(name: String, mediaURL: URL, mediaExt: String, language: String, duratinInS: Int, sizeInBytes: Int) -> Video {
        self.name = name
        self.mediaURLString = mediaURL.absoluteString
        self.mediaExt = mediaExt
        self.language = language
        self.durationInSeconds = Int64(duratinInS)
        self.sizeInBytes = Int64(sizeInBytes)
        return self
    }
    
}
