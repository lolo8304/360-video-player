//
//  Connector.swift
//  SecondScreen
//
//  Created by Lorenz Hänggi on 28.12.16.
//  Copyright © 2016 Lorenz Hänggi. All rights reserved.
//

import Foundation

protocol ConnectorDelegate {
    func deviceConnected(device: Device)
    func deviceDisconnected(device: Device)
    func deviceSelected(device: Device)
    func statusChanged(started: Bool, server:ConnectorStatus, bonjourServer: ConnectorBonjourStatus, connections: Int)
    func sendAction(action: String, data: JSON);
    func playerUpdated(device: Device, player: DevicePlayer);

}

enum ConnectorStatus {
    case Starting
    case Ready
    case Connected
    case Stopping
    case Stopped
}
enum ConnectorBonjourStatus {
    case Starting
    case Ready
    case Stopping
    case Stopped
}

enum DeviceStatus {
    case closed
    case accepted
    case connected
    case selected
}

enum DevicePlayerStatus {
    case stopped
    case paused
    case playing
    case synchronizing
}


class DevicePlayer : NSObject {
    public var name: String = ""
    public var medianame: String = ""
    public var language: String = "DE"
    public var status: DevicePlayerStatus = .stopped
    public var position: Int = 0
    public var duration: Int = 0
    
    override init() {
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
    public func handleAction(_ action: String, data: JSON) {
        self.name = self.getAttrName(data)
        self.medianame = self.name
        self.language = self.getAttrLanguage(data)
        switch action {
        case "player-prepare":
            self.duration = self.getAttrDuration(data)
            self.status = .stopped
        case "player-seek":
            self.position = self.getAttrSeek(data)
        case "player-start":
            self.position = self.getAttrSeek(data)
            self.status = .playing
        case "player-pause":
            self.position = self.getAttrSeek(data)
            self.status = .paused
        case "player-stop":
            self.position = self.getAttrSeek(data)
            self.status = .stopped
        case "player-keepAlive":
            self.position = self.getAttrSeek(data)
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

class Device: NSObject {
    
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
    public let player: DevicePlayer = DevicePlayer()
    

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
    
}

class Connector: NSObject {
    
    static let instance: Connector = {
        return Connector()
    }()
    
    private var socketServer: SecondScreenServer?
    private var tempConnectedDevices = [ String : Device ]()
    private var connectedDevicesByWebSocket = [ PSWebSocket : Device ]()
    public var selectedDevice: Device?
    
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
            self.selectedDevice = device
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
    
    public func get(deviceIp: String) -> Device? {
        self.choose(ip: deviceIp)
        return self.selectedDevice
    }
    public func get(webSocket: PSWebSocket) -> Device? {
        return self.connectedDevicesByWebSocket[webSocket]
    }
    
    public func choose(device: Device) {
        self.selectedDevice = device
    }
    public func choose(id: Int) {
        for (_, value) in self.connectedDevicesByWebSocket {
            if (value.id == id) {
                self.choose(device: value)
                return
            }
        }
        self.selectedDevice = nil
    }
    public func choose(ip: String) {
        for (_, value) in self.connectedDevicesByWebSocket {
            if (value.ip == ip) {
                self.choose(device: value)
                return
            }
        }
        for (_, value) in self.tempConnectedDevices {
            if (value.ip == ip) {
                self.choose(device: value)
                return
            }
        }
        self.selectedDevice = nil
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

    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didReceiveMessage message: Any!) {
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
                
                //CurrentQuaternion.instance().enqueue(json["X"].floatValue, add: json["Y"].floatValue, add: json["Z"].floatValue, add: json["W"].floatValue)
                CurrentQuaternion.instance().enqueue(json["pitchX"].floatValue, add: json["rollY"].floatValue, add: json["yawZ"].floatValue)
                //NSLog("queue size = \(CurrentQuaternion.instance().count())");
            } else if (action == "disconnect") {
                    device?.disconnect()
                    var connectionResponse = JSON.init(["device.uuid": device!.uuid]);
                    webSocket.send(json: &connectionResponse, action: "disconnected");
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
                let device: Device? = self.get(deviceIp: json["ip"].stringValue)
                if (device != nil) {
                    device!.connect(webSocket: webSocket)
                    var connectionResponse = JSON.init(["device.uuid": device!.uuid]);
                    NSLog("send connected back to device \(device!.ip)")
                    webSocket.send(json: &connectionResponse, action: "connected");
                } else {
                    var connectionResponse = JSON.init(["message": "no device found on that IP"]);
                    webSocket.send(json: &connectionResponse, action: "connection-failed");
                }
            }
        }
    }
    
    func serverDidStop(_ server: PSWebSocketServer!) {
        self.changeState(server: .Stopped)
        self.stopTimer()
    }
    func serverDidStart(_ server: PSWebSocketServer!) {
        self.changeState(server: .Ready)
        self.startTimer()
    }
    func server(_ server: PSWebSocketServer!, webSocketDidOpen webSocket: PSWebSocket!) {
        let acknowledgeRequest = JSON.init(["action": "request-connection-data", "device.ip": "", "device.uuid": ""])
        webSocket.send(acknowledgeRequest.rawString())
    }
    
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didFailWithError error: Error!) {
        //self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    public func server(_ server: PSWebSocketServer!, didFailWithError error: Error!) {
        self.showError("webSocket didFailWithError \(error!)", stack: true)
    }
    func server(_ server: PSWebSocketServer!, webSocket: PSWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.showError("didCloseWithCode code=\(code), reason=\(reason)", stack: false)
    }
    func server(_ server: PSWebSocketServer!, acceptWebSocketWith request: URLRequest!, address: Data!, trust: SecTrust!, response: AutoreleasingUnsafeMutablePointer<HTTPURLResponse?>!) -> Bool {
        
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
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
    }
}

extension Connector : NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        NSLog("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        self.changeState(bonjourServer: .Ready)
    }
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("Failed to Publish: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("Bonjour Service Did Resolved Address: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    func netServiceDidStop(_ sender: NetService) {
        NSLog("Bonjour Service Did Stop: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
        self.changeState(bonjourServer: .Stopped)
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        NSLog("Bonjour Service did not resolve: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) host(\(sender.hostName)) port(\(sender.port))");
    }
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        
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
    func send(json: inout JSON, action: String) {
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

    internal func deviceDisconnected(device: Device) {
        
    }

    internal func deviceConnected(device: Device) {
        
    }

    
}
