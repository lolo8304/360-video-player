//
//  Content.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 22.01.17.
//  Copyright © 2017 Lorenz Hänggi. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import AVFoundation

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
    public func languageFlag() -> String {
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

public class Content : NSObject {
    public static let instance: Content = {
        return Content().load()
    }()
    
    public var videos: [Video] = []
    
    private override init() {
    }
    
    public func getVideo(name: String) -> Video? {
        for video in self.videos {
            if (video.name?.lowercased() == name.lowercased()) { return video }
        }
        return nil;
    }
    
    public func addNewVideo(_ newVideo: Video) -> Bool {
        if (self.getVideo(name: newVideo.name!) != nil) {
            return false
        }
        do {
            self.videos.append(newVideo)
            try newVideo.managedObjectContext?.save()
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    public func updateVideo(_ video: Video) -> Bool {
        let old: String = video.name!
        video.name = "$$\(old)"
        let existingVideo = self.getVideo(name: old)
        video.name = old
        if (existingVideo != nil && existingVideo != video) {
            return false
        }
        do {
            try video.managedObjectContext?.save()
            return true
        } catch {
            print(error)
            return false
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
    public func reload() -> Content {
        self.videos = []
        return self.load()
    }
    public func reset() -> Content {
        for video in self.videos {
            video.delete()
        }
        return self.reload()
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
        let path = Bundle.init(for: Content.self).path(forResource: name, ofType: "json")
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

public extension Video {
    
    public static let LANGUAGES: [String] = ["Deutsch : DE", "English : EN", "Francais : FR", "Italiano : IT"]
    public static let MEDIA_EXT: [String] = ["mp4"]
    public static let VERSIONS: [String] = ["standard", "long", "short", "teaser"]
    public static let _360_TYPES: [String] = ["no 360: no", "360 sphere : _360", "Panorama Top/Bottom: _360_TB", "Panorama Bottom/Top: _360_BT", "Panorama Left/Right: _360_LR", "Panorama Right/Left: _360_RL"]
    
    
    public func delete() {
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
    
    private func updateSizeAndDuration() {
        if (self.mediaURLString!.hasPrefix("assets-library://")) {
            let asset: AVURLAsset = AVURLAsset(url: self.mediaURL())
            let track: AVAssetTrack = asset.tracks[0]
            NSLog("track naturalSize h=\(track.naturalSize.height) + w=\(track.naturalSize.width)")
            self.sizeInBytes = Int64(track.naturalSize.height * track.naturalSize.width)
        } else {
            let playerItem: AVPlayerItem = AVPlayerItem(url: self.mediaURL())
            let duration: CMTime = playerItem.duration
            if (duration.isValid && !duration.isIndefinite) {
                self.durationInSeconds = Int64(CMTimeGetSeconds(duration))
            } else {
                self.durationInSeconds = 0
            }
            self.duration = self.durationInSeconds.fromSecToTime()
        }
        
        do {
            let properties: [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: self.mediaURLString!)
            let size: NSNumber = properties[FileAttributeKey.size] as! NSNumber
            self.sizeInBytes = size.int64Value
        } catch {
            print(error)
            self.sizeInBytes = 0
            return
        }
    }
    
    public func from(json: JSON) -> Video {
        self.name = json.getAttrName()
        self.mediaURLString = json.getAttrMediaName()
        self.mediaExt = json.getAttrMediaExt()
        self.language = json.getAttrLanguage()
        self.durationInSeconds = Int64(json.getAttrDuration().fromTimeToSeconds())
        self.sizeInBytes = Int64(json.getAttrSizeInBytes())
        self.updateSizeAndDuration()
        return self
    }
    public func from(name: String, mediaURL: URL, mediaExt: String, language: String, duratinInS: Int, sizeInBytes: Int) -> Video {
        self.name = name
        self.mediaURLString = mediaURL.absoluteString
        self.mediaExt = mediaExt
        self.language = language
        self.durationInSeconds = Int64(duratinInS)
        self.sizeInBytes = Int64(sizeInBytes)
        self.updateSizeAndDuration()
        return self
    }
    
}
