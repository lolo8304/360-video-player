//
//  Connector.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation
import SwiftyJSON
import PocketSocket
import CocoaAsyncSocket
import SecondScreenShared


public protocol ConnectorDelegate {
    func deviceConnected(device: Device)
    func deviceDisconnected(device: Device)
    func deviceSelected(device: Device)
    func deviceDeselected(device: Device)
    func noDeviceSelected()
    func statusChanged(started: Bool, server:ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int)
    func sendAction(action: String, data: JSON);
    func playerUpdated(device: Device, player: DevicePlayer);

}

public enum ConnectorStatus {
    case Starting
    case Ready
    case Connected
    case Stopping
    case Stopped
}
public enum ConnectorBonjourStatus {
    case Starting
    case Ready
    case Stopping
    case Stopped
}

public enum DeviceStatus {
    case closed
    case accepted
    case connected
    case selected
}

public enum DevicePlayerStatus {
    case stopped
    case paused
    case playing
    case synchronizing
}


public class DevicePlayer : NSObject {
    public var device: Device
    public var name: String = ""
    public var medianame: String = ""
    public var language: String = "DE"
    public var video: Video?
    public var status: DevicePlayerStatus = .stopped
    public var position: Int = 0
    public var duration: Int = 0
    
    init(device: Device) {
        self.device = device
    }
    
    private func getString(_ data: JSON, attribute: String) -> String {
        return data[attribute].stringValue
    }
    private func getInt(_ data: JSON, attribute: String) -> Int {
        return data[attribute].intValue
    }
    
    private func getAttrName(_ data: JSON) -> String {
        return self.getString(data, attribute: "name")
    }
    private func getAttrLanguage(_ data: JSON) -> String {
        return self.getString(data, attribute: "language")
    }
    private func getAttrDuration(_ data: JSON) -> Int {
        return self.getInt(data, attribute: "duration")
    }
    private func getAttrSeek(_ data: JSON) -> Int {
        return self.getInt(data, attribute: "seek")
    }
    
    func loadNewVideoNamed(name: String) {
        self.name = name
        if (!name.isEmpty) {
            self.video = Content.instance.getVideo(name: self.name)
        } else {
            self.video = nil
        }
    }
    public func handleFirstPositionAction(data: JSON) {
        self.loadNewVideoNamed(name: self.getAttrName(data))
        self.position = self.getAttrSeek(data)
        if (self.video != nil) {
            let action: PlayerAction = PlayerAction(self, prepareVideo: self.name, mediaURL: video!.mediaURL(), ext: video!.mediaExt, at: Int32(self.position))
            CurrentQuaternion.instance().enqueue(action)
        } else {
            NSLog("remote Video play not found '\(self.name)'")
            let action: PlayerAction = PlayerAction(self, stopAt: 0)
            CurrentQuaternion.instance().enqueue(action)
        }
    }
    
    private func verifyName(_ data: JSON) -> Bool {
        return self.name == self.getAttrName(data);
    }
    public func handleAction(_ action: String, data: JSON) {
        if (action == "player-prepare") {
            self.name = self.getAttrName(data)
            self.duration = self.getAttrDuration(data)
            self.position = self.getAttrSeek(data)
            self.status = .stopped
            return
        }
        
        //if (!self.verifyName(data)) { return }
        self.loadNewVideoNamed(name: self.getAttrName(data))
        self.position = self.getAttrSeek(data)
        switch action {
        case "player-seek":
            let action: PlayerAction = PlayerAction(self, seekAt: Int32(self.position))
            CurrentQuaternion.instance().enqueue(action)
        case "player-start":
            self.status = .playing
            let action: PlayerAction = PlayerAction(self, playAt: Int32(self.position))
            CurrentQuaternion.instance().enqueue(action)
        case "player-pause":
            self.status = .paused
            let action: PlayerAction = PlayerAction(self, pauseAt: Int32(self.position))
            CurrentQuaternion.instance().enqueue(action)
        case "player-stop":
            self.status = .stopped
            let action: PlayerAction = PlayerAction(self, stopAt: -1)
            CurrentQuaternion.instance().enqueue(action)
        case "player-keepAlive":
            self.status = .playing
            break
        default:
            return
        }
    }
    
    public func positionTime() ->String {
        var seconds: Int = self.position / 1000
        let minutes: Int = seconds / 60
        seconds = seconds % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
    public func positionPercentage() -> Int {
        if (self.position == 0) { return 0 }
        return self.duration * 100 / self.duration
    }
    
    public func isPlaying() -> Bool {
        return self.status == .playing
    }
    public func isSynchronizing() -> Bool {
        return self.status == .synchronizing
    }
    public func isStopped() -> Bool {
        return !self.isPlaying() && !self.isSynchronizing()
    }
}

public class Device: NSObject {
    
    private static var maxId: Int = 0
    
    public var id: Int
    public var connector: Connector
    public var uuid: String
    public var ip: String
    public var name: String
    public var webSocket: PSWebSocket? = nil
    public var status: DeviceStatus = .closed
    public var pinged: Bool = false
    public var ponged: Bool = false
    lazy public var player: DevicePlayer = {
       return DevicePlayer(device: self)
    }()
    

    public static func create(connector: Connector, uuid: String, ip: String, name: String) -> Device {
        let device: Device = Device(connector: connector, uuid: uuid, ip: ip, name: name)
        connector.add(device: device)
        return device
    }
    public static func create(connector: Connector, json: JSON) -> Device {
        let device: Device = Device(connector: connector, json: json)
        connector.add(device: device)
        return device
    }
    private init(connector: Connector, uuid: String, ip: String, name: String) {
        Device.maxId = Device.maxId + 1
        self.id = Device.maxId
        self.connector = connector
        self.uuid = uuid
        self.ip = ip
        self.name = name
    }
    private init(connector: Connector, json: JSON) {
        Device.maxId = Device.maxId + 1
        self.id = Device.maxId
        self.connector = connector
        self.uuid = json["device.uuid"].string!
        self.ip = json["device.ip"].string!
        self.name = json["device.name"].string!
    }
    public func connect() {
        self.connector.add(device: self)
    }
    public func connect(webSocket: PSWebSocket) {
        if (self.isConnected()) {
            self.disconnect()
        }
        self.webSocket = webSocket
        self.connect()
        self.status = .connected
    }
    public func select() {
        self.status = .selected
    }
    public func deselect() {
        self.status = .connected
    }
    public func disconnect() {
        self.connector.remove(device: self)
    }
    
    public func isConnected() -> Bool {
        return self.webSocket != nil
    }
    public func getConnection() -> PSWebSocket {
        return self.webSocket!
    }
    
    public func play() {
        CurrentQuaternion.instance().play()
    }
    public func stop() {
        CurrentQuaternion.instance().stop()
    }
    
    public func toJSON() -> JSON {
        return JSON.init(["name": self.name, "ip": self.ip, "uuid": self.uuid, "status" : "\(self.status)"])
    }
    public func toString() -> String {
        let json: JSON = self.toJSON()
        let jsonString: String? = json.rawString(.utf8, options: .prettyPrinted)
        return jsonString!
    }
    
    
    public func send(action: String, name: String, message: String) {
        let localMessage:JSON = JSON.init([ name : message])
        self.send(action: action, message: localMessage)
    }
    public func send(action: String) {
        let message:JSON = JSON.init(["id" : self.id])
        self.send(action: action, message: message)

    }
    public func send(action: String, message: JSON) {
        var localMessage = message
        localMessage["device.uuid"].stringValue = self.uuid
        localMessage["device.ip"].stringValue = self.ip
        webSocket!.send(action: action, json: &localMessage);
    }
    
}

public class Connector: NSObject {
    
    static let instance: Connector = {
        return Connector()
    }()
    
    private var socketServer: SecondScreenServer?
    private var tempConnectedDevices = [ String : Device ]()
    private var connectedDevicesByWebSocket = [ PSWebSocket : Device ]()
    private var selectedDevice: Device?
    
    public var delegate: ConnectorDelegate
    public var status: ConnectorStatus = .Stopped
    public var bonjourStatus: ConnectorBonjourStatus = .Stopped

    private var needRestart = false
    private var timer = Timer()
    
    private override init() {
        self.delegate = ConnectorNoDelegate()
    }
    
    // timer functions
    
    fileprivate func startTimer() {
        let aSelector : Selector = #selector(Connector.validateDevices)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: aSelector, userInfo: nil, repeats: true)
    }
    fileprivate func stopTimer() {
        timer.invalidate()
    }
    
    /*
    func pongResult (pongData: Data?) -> Void {
        let pongDataString: String = pongData!.base64EncodedString()
        NSLog("Pong arrived \(pongDataString)")
    }
     webSocket.ping(pingData, handler: pongResult)

    */

    public func validateDevices() {
        if (self.connectedDevicesByWebSocket.count == 0) { return }
        var allNonValidDevices = [PSWebSocket : Device]()
        var allValidDevices = [PSWebSocket : Device]()
        for (key, value) in (self.connectedDevicesByWebSocket) {
            if (value.pinged && value.ponged) {
                //NSLog("validation: valid device \(value.ip)")
                allValidDevices[key] = value
                value.pinged = false
                value.ponged = false
            } else if (value.pinged && !value.ponged) {
                allNonValidDevices[key] = value
            } else {
                let pingData: Data = "hello-from-server".data(using: .utf8)!
                value.pinged = true
                key.ping(pingData, handler: { (pongData) in
                    value.ponged = true
                })
            }
        }
        if (!allNonValidDevices.isEmpty) {
            NSLog("validate all \(self.connectedDevicesByWebSocket.count) devices")
            for (_, value) in allNonValidDevices {
                NSLog("validation: non valid device \(value.ip)")
                value.disconnect()
            }
        }
    }
    
    

    private func delayedStart() {
        self.needRestart = false
        self.socketServer = nil
        self.changeState(server: .Starting)
        self.changeState(bonjourServer: .Starting)
        self.socketServer = SecondScreenServer(port: 6577)
        self.socketServer?.start(delegate: self, udpDelegate: self, bonjourDelegate: self)
    }
    
    // server activities
    public func startServer() {
        if (self.isStarted()) { return }
        if (!self.isStopped()) {
            self.needRestart = true
            self.socketServer?.stop()
        } else {
            self.delayedStart()
        }
    }
    public func stopServer() {
        if (self.isStopped()) { return }
        self.changeState(server: .Stopping)
        self.changeState(bonjourServer: .Stopping)
        
        self.socketServer?.stop()
        self.socketServer = nil
    }
    public func isStarted() -> Bool {
        return (self.status == .Ready || self.status == .Connected) && (self.bonjourStatus == .Ready)
    }
    public func isStopped() -> Bool {
        return (self.status == .Stopped) && (self.bonjourStatus == .Stopped)
    }
    public func endPoint() -> String {
        return self.isStarted() ? self.socketServer!.endPoint() : "none"
    }

    private func statusChanged() {
        self.delegate.statusChanged(started: self.isStarted(), server: self.status, bonjourServer: self.bonjourStatus, connections: self.connectedDevicesByWebSocket.count)
        if (self.isStopped() && self.needRestart) {
            self.delayedStart()
        }
    }
    // state management
    func changeState(server: ConnectorStatus) {
        self.status = server
        self.statusChanged()
    }
    func changeState(bonjourServer: ConnectorBonjourStatus) {
        self.bonjourStatus = bonjourServer
        self.statusChanged()
    }
    func refreshState() {
        self.statusChanged()
    }

    
    // device management

    public func add(device: Device) {
        let ip: String = device.ip
        NSLog("register device: \(ip), data=\(device.toString())")
        if (device.isConnected()) {
            if (self.tempConnectedDevices[ip] == device) {
                self.tempConnectedDevices.removeValue(forKey: device.ip)
            }
            self.connectedDevicesByWebSocket[device.webSocket!] =  device
            NSLog("register websocket of device: \(ip), data=\(device.toString())")
            self.status = .Connected
            self.statusChanged()
            self.delegate.deviceConnected(device: device)
        } else {
            self.tempConnectedDevices[device.ip] = device
        }
    }

    public func add(json: JSON) {
        self.add(device: Device.create(connector: self, json: json))
    }
    public func remove(device: Device) {
        if (device.isConnected()) {
            self.connectedDevicesByWebSocket.removeValue(forKey: device.webSocket!)
            NSLog("remove connected device: \(device.ip), data=\(device.toString())")
            if (self.connectedDevicesByWebSocket.count == 0) {
                self.status = .Ready
            }
            self.statusChanged()
            self.delegate.deviceDisconnected(device: device)
        }
    }
    
    public func get(id: Int) -> Device? {
        for (_, value) in self.connectedDevicesByWebSocket {
            if (value.id == id) {
                return value
            }
        }
        for (_, value) in self.tempConnectedDevices {
            if (value.id == id) {
                return value
            }
        }
        return nil
    }
    public func get(ip: String) -> Device? {
        for (_, value) in self.connectedDevicesByWebSocket {
            if (value.ip == ip) {
                return value
            }
        }
        for (_, value) in self.tempConnectedDevices {
            if (value.ip == ip) {
                return value
            }
        }
        return nil
    }
    public func get(webSocket: PSWebSocket) -> Device? {
        return self.connectedDevicesByWebSocket[webSocket]
    }
    
    public func choose(device: Device?) {
        if (self.selectedDevice == device) {
            return
        }
        if (self.selectedDevice != nil) {
            self.selectedDevice!.send(action: "deselected")
            self.selectedDevice!.deselect()
            self.delegate.deviceDeselected(device: self.selectedDevice!)
        }
        if (device != nil) {
            device!.send(action: "selected")
            device!.select()
            self.delegate.deviceSelected(device: device!)
        } else {
            self.delegate.noDeviceSelected()
        }
        self.selectedDevice = device
    }
    
    public func choose(id: Int) {
        self.choose(device: self.get(id: id))
    }
    public func choose(ip: String) {
        self.choose(device: self.get(ip: ip))
    }
    
    public func sortedDevicesById() -> [Device] {
        var list: [Device] = [Device]();
        for (_, value) in self.connectedDevicesByWebSocket {
            list.append(value)
        }
        list.sort {
            $0.id < $1.id
        }
        return list
    }
    
    public func play() {
        self.selectedDevice?.play()
    }

    // logs

     func appendLog(_ message: String) {
        NSLog("message arrived: \(message)")
    }
     func showError(_ message: String, stack: Bool) {
        if (stack) {
            NSLog("error message \(message): see stack")
            for symbol: String in Thread.callStackSymbols {
                NSLog("%@", symbol)
            }
        } else {
            NSLog("error message \(message)")
        }
    }

}

extension Connector : PSWebSocketServerDelegate {

    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
        self.server(server, webSocket: webSocket, didReceive: message as! String)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceive message: String!) {
        let device: Device? = self.get(webSocket: webSocket)
        if (device != nil) {
            device!.pinged = true
            device!.ponged = true
            let json:JSON = JSON.init(data: message.data(using: .utf8, allowLossyConversion: false)!)
            let action = json["action"].stringValue
            if (action == "position") {
                CurrentQuaternion.instance().enqueue(Int32(json["seek"].intValue), add: json["rollY"].floatValue, add: json["yawZ"].floatValue, add: json["pitchX"].floatValue)
            } else if (action == "positionAndPrepare") {
                device!.player.handleFirstPositionAction(data: json)
                delegate.playerUpdated(device: device!, player: device!.player)
                CurrentQuaternion.instance().enqueue(Int32(json["seek"].intValue), add: json["pitchX"].floatValue, add: json["rollY"].floatValue, add: json["yawZ"].floatValue)
            } else if (action == "disconnect") {
                    device?.disconnect()
                    var connectionResponse = JSON.init(["device.uuid": device!.uuid]);
                    webSocket.send(action: "disconnected", json: &connectionResponse);
            } else if (action.hasPrefix("player-")) {
                device!.player.handleAction(action, data: json)
                delegate.playerUpdated(device: device!, player: device!.player)
                delegate.sendAction(action: action, data: json)
            } else if (action != "") {
                delegate.sendAction(action: action, data: json)
            }
        } else {
            let json: JSON = JSON.init(data: message.data(using: .utf8)!)
            if (json["action"].stringValue == "request-connection-data") {
                // retrieve IP, name of device to map it with device-object and websocket
                let device: Device? = self.get(ip: json["ip"].stringValue)
                if (device != nil) {
                    device!.connect(webSocket: webSocket)
                    var connectionResponse = JSON.init(["device.uuid": device!.uuid]);
                    NSLog("send connected back to device \(device!.ip)")
                    webSocket.send(action: "connected", json: &connectionResponse);
                } else {
                    var connectionResponse = JSON.init(["message": "no device found on that IP"]);
                    webSocket.send(action: "connection-failed", json: &connectionResponse);
                }
            }
        }
    }
    
    public func serverDidStop(_ server: PSWebSocketServer!) {
        self.changeState(server: .Stopped)
        self.stopTimer()
    }
    public func serverDidStart(_ server: PSWebSocketServer!) {
        self.changeState(server: .Ready)
        self.startTimer()
    }
    public func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        let acknowledgeRequest = JSON.init(["action": "request-connection-data", "device.ip": "", "device.uuid": ""])
        webSocket.send(acknowledgeRequest.rawString())
    }
    
    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        //self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    public func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    public func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.showError("didCloseWithCode code=\(code), reason=\(reason)", stack: false)
    }
    public func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!, address: Data!, trust: SecTrust!, response: AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>!) -> Bool {
        
        if (PSWebSocket.isWebSocketRequest(request)) {
            let headers: [String : String] = request.allHTTPHeaderFields!
            let deviceId: JSON = self.getDeviceId(headers: headers)
            let device: Device = Device.create(connector: self, json: deviceId)
            device.status = .accepted
            return true
        } else {
            return false
        }
    }
    fileprivate func getDeviceId(headers: [String : String]) -> JSON {
        var deviceName: String = "none"
        var deviceIp: String = "0.0.0.0"
        var deviceUUID: String = ""
        for (key, value) in headers {
            if (key == "device.name") { deviceName = value }
            if (key == "device.ip") { deviceIp = value }
            if (key == "Sec-WebSocket-Key") { deviceUUID = value }
        }
        return JSON.init(["device.name": deviceName, "device.ip": deviceIp, "device.uuid": deviceUUID])
    }
}


extension Connector : GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
    }
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
    }
}

extension Connector : NetServiceDelegate {
    public func netServiceDidPublish(_ sender: NetService) {
        NSLog("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        self.changeState(bonjourServer: .Ready)
    }
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        
    }
    public func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("Bonjour Service Did Resolved Address: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    public func netServiceDidStop(_ sender: NetService) {
        NSLog("Bonjour Service Did Stop: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        self.changeState(bonjourServer: .Stopped)
    }
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        NSLog("Bonjour Service did not resolve: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    public func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        
    }

}


extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

extension PSWebSocket {
    func send(json: JSON) {
        self.send(json.rawString())
    }
    func send(action: String, json: inout JSON) {
        json["action"].stringValue = action
        self.send(json.rawString())
    }
}



class ConnectorNoDelegate: ConnectorDelegate {

    internal func playerUpdated(device: Device, player: DevicePlayer) {
        
    }

    internal func sendAction(action: String, data: JSON) {
        
    }

    internal func statusChanged(started: Bool, server: ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int) {
        
    }

    internal func deviceSelected(device: Device) {
        
    }
    func deviceDeselected(device: Device) {
        
    }
    func noDeviceSelected() {
        
    }

    internal func deviceDisconnected(device: Device) {
        
    }

    internal func deviceConnected(device: Device) {
        
    }

    
}
